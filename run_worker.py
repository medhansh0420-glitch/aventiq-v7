"""Scheduled RSS/Atom worker. Candidates are never published unless an owner enables a strict policy."""
from __future__ import annotations
import os, logging
from datetime import datetime, timezone, timedelta, date
from supabase import create_client
from workers.discovery.pipeline import run_source
from workers.discovery.verify import verify_url
from workers.discovery.scoring import score_record
from workers.extraction.openai_extract import extract_opportunity

logging.basicConfig(level=os.getenv('LOG_LEVEL','INFO')); log=logging.getLogger('aventiq-worker')

def now(): return datetime.now(timezone.utc).isoformat()
def iso_date(value):
    if not isinstance(value,str): return None
    try: return date.fromisoformat(value[:10]).isoformat()
    except ValueError: return None
def run():
    db=create_client(os.environ['NEXT_PUBLIC_SUPABASE_URL'],os.environ['SUPABASE_SERVICE_ROLE_KEY'])
    jobs=db.table('processing_jobs').select('*').eq('status','queued').eq('job_type','scan_sources').lte('available_at',now()).order('created_at').limit(10).execute().data or []
    requested_ids=set()
    for job in jobs:
        db.table('processing_jobs').update({'status':'running','locked_at':now(),'attempts':(job.get('attempts') or 0)+1}).eq('id',job['id']).execute()
        if job.get('payload',{}).get('source_id'): requested_ids.add(job['payload']['source_id'])
    sources=db.table('opportunity_sources').select('*').eq('is_active',True).execute().data or []
    if requested_ids: sources=[s for s in sources if s['id'] in requested_ids]
    elif not jobs:
        now_dt=datetime.now(timezone.utc)
        sources=[s for s in sources if not s.get('last_scanned_at') or datetime.fromisoformat(s['last_scanned_at'].replace('Z','+00:00')) <= now_dt-timedelta(minutes=int(s.get('scan_interval_minutes') or 360))]
    settings=db.table('system_settings').select('key,value').in_('key',['auto_publish_enabled','min_confidence']).execute().data or []
    settings_map={x['key']:x['value'] for x in settings}
    auto_publish=bool(settings_map.get('auto_publish_enabled',False))
    os.environ['WORKER_MIN_CONFIDENCE']=str(settings_map.get('min_confidence',os.getenv('WORKER_MIN_CONFIDENCE','0.95')))
    source_failures=0
    for source in sources:
        runrow=db.table('discovery_runs').insert({'source_id':source['id'],'status':'running','started_at':now()}).execute().data[0]
        found=created=0
        try:
            entries=run_source(source['url'],source['name'],source.get('source_type','rss')); found=len(entries)
            for item in entries:
                raw=db.table('discovered_items').upsert({'source_id':source['id'],'discovery_run_id':runrow['id'],'external_hash':item['external_hash'],'raw_payload':item},on_conflict='external_hash',ignore_duplicates=True).execute()
                if not raw.data: continue
                try:
                    extracted=extract_opportunity(item['title'],item.get('description') or '',item['official_source_url'])
                    record={k:v for k,v in extracted.items() if v is not None}
                    record['official_source_url']=item['official_source_url']
                    for date_field in ('start_date','deadline'):
                        record[date_field]=iso_date(record.get(date_field))
                    if record.get('application_url'):
                        verification=verify_url(record['application_url'])
                    else:
                        verification={'valid':False,'reason':'application_url_missing','status_code':None,'final_url':None}
                    official_verification=verify_url(record['official_source_url']) if record.get('official_source_url') else {'valid':False,'reason':'official_source_url_missing','status_code':None,'final_url':None}
                    from difflib import SequenceMatcher
                    existing=db.table('opportunities').select('id,title,organization').ilike('organization',record.get('organization') or '___NO_ORG___').limit(50).execute().data or []
                    duplicate=None; duplicate_similarity=0.0
                    for candidate in existing:
                        similarity=SequenceMatcher(None,(candidate.get('title') or '').lower(),(record.get('title') or '').lower()).ratio()
                        if similarity>=0.88 and similarity>duplicate_similarity: duplicate=candidate; duplicate_similarity=similarity
                    score=score_record(record,float(source.get('reliability') or .5),bool(verification['valid']),bool(duplicate),bool(official_verification['valid']))
                    publish=auto_publish and score['decision']=='auto_publish_candidate'
                    record.update({'status':'published' if publish else 'pending_review','published_at':now() if publish else None,'last_verified_at':now() if verification['valid'] and official_verification['valid'] else None,'confidence':score['confidence'],'confidence_explanation':{'blockers':score['blockers'],'decision':score['decision'],'source_reliability':source.get('reliability')}})
                    ins=db.table('opportunities').insert(record).execute()
                    if ins.data:
                        oid=ins.data[0]['id']; created+=1
                        db.table('discovered_items').update({'processing_status':'processed','opportunity_id':oid}).eq('id',raw.data[0]['id']).execute()
                        db.table('ai_processing_logs').insert({'discovered_item_id':raw.data[0]['id'],'opportunity_id':oid,'model':os.getenv('OPENAI_MODEL','gpt-4.1-mini'),'status':'succeeded','details':{'confidence':score['confidence'],'blockers':score['blockers']}}).execute()
                        db.table('verification_logs').insert({'opportunity_id':oid,'check_type':'application_url','result':'reachable' if verification['valid'] else 'unavailable','details':verification}).execute()
                        db.table('verification_logs').insert({'opportunity_id':oid,'check_type':'official_source_url','result':'reachable' if official_verification['valid'] else 'unavailable','details':official_verification}).execute()
                        if duplicate: db.table('opportunity_duplicates').insert({'opportunity_id':oid,'possible_duplicate_id':duplicate['id'],'similarity':round(duplicate_similarity,3),'resolution':'unresolved'}).execute()
                except Exception as candidate_error:
                    log.exception('Candidate processing failed')
                    db.table('ai_processing_logs').insert({'discovered_item_id':raw.data[0]['id'],'model':os.getenv('OPENAI_MODEL','gpt-4.1-mini'),'status':'failed','details':{'error':str(candidate_error)[:300]}}).execute()
                    db.table('discovered_items').update({'processing_status':'failed'}).eq('id',raw.data[0]['id']).execute()
            db.table('opportunity_sources').update({'last_scanned_at':now(),'last_scan_result':f'{found} found; {created} candidates'}).eq('id',source['id']).execute()
            db.table('discovery_runs').update({'status':'succeeded','items_found':found,'items_created':created,'finished_at':now()}).eq('id',runrow['id']).execute()
        except Exception as exc:
            source_failures+=1
            log.exception('Source scan failed')
            db.table('discovery_runs').update({'status':'failed','error_message':str(exc)[:500],'finished_at':now()}).eq('id',runrow['id']).execute()
    for job in jobs:
        attempts=int(job.get('attempts') or 0)
        if source_failures and attempts<3:
            from datetime import timedelta
            retry_at=(datetime.now(timezone.utc)+timedelta(minutes=min(60,5*(2**attempts)))).isoformat()
            db.table('processing_jobs').update({'status':'queued','available_at':retry_at,'last_error':'One or more source scans failed'}).eq('id',job['id']).execute()
        else:
            job_status='failed' if source_failures or not sources else 'succeeded'
            db.table('processing_jobs').update({'status':job_status,'last_error':'Source scan failed' if source_failures else None}).eq('id',job['id']).execute()

if __name__=='__main__': run()
