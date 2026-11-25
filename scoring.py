"""Conservative confidence scoring. Mandatory missing facts always block auto-publishing."""
import os

def score_record(record: dict, source_reliability: float, url_valid: bool, duplicate: bool, official_source_valid: bool = True) -> dict:
    fields=['title','description','organization','category','official_source_url','application_url']
    completeness=sum(bool(record.get(k)) for k in fields)/len(fields)
    source=max(0.0,min(1.0,float(source_reliability)))
    score=round(.30*source+.45*completeness+.25*float(url_valid and official_source_valid),3)
    blockers=[]
    for field in ('title','organization','category','official_source_url','application_url','deadline'):
        if not record.get(field): blockers.append('missing_'+field)
    if not url_valid: blockers.append('application_url_not_verified')
    if not official_source_valid: blockers.append('official_source_url_not_verified')
    if duplicate: blockers.append('possible_duplicate')
    threshold=float(os.getenv('WORKER_MIN_CONFIDENCE','0.95'))
    return {'confidence':score,'blockers':blockers,'decision':'auto_publish_candidate' if score>=threshold and not blockers else 'pending_review'}
