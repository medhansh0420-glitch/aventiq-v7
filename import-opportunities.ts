import { createClient } from '@supabase/supabase-js';
import { OPPORTUNITIES } from './opportunities';

const url=process.env.NEXT_PUBLIC_SUPABASE_URL;
const key=process.env.SUPABASE_SERVICE_ROLE_KEY;
if(!url||!key)throw new Error('Set NEXT_PUBLIC_SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY in a trusted local shell.');
const db=createClient(url,key,{auth:{persistSession:false,autoRefreshToken:false}});
const isoDate=(value:string)=>/^\d{4}-\d{2}-\d{2}$/.test(value||'')?value:null;
async function main(){
 console.log(`Importing ${OPPORTUNITIES.length} preserved legacy opportunities as pending review...`);
 if(OPPORTUNITIES.length!==1055)throw new Error(`Expected exactly 1,055 records; found ${OPPORTUNITIES.length}. Import stopped.`);
 for(let i=0;i<OPPORTUNITIES.length;i+=100){
  const batch=OPPORTUNITIES.slice(i,i+100).map(o=>({legacy_id:o.id,title:o.title,organization:o.organization||null,category:o.category||null,description:o.description||null,location:o.location||null,target_audience:o.targetAudience||null,eligibility:o.educationLevel||null,deadline:isoDate(o.deadline),legacy_deadline:o.deadline||null,legacy_url:o.url||null,legacy_status:o.status||null,legacy_verification_status:o.verificationStatus||null,application_url:o.url||null,official_source_url:o.url||null,status:'pending_review'}));
  const {error}=await db.from('opportunities').upsert(batch,{onConflict:'legacy_id'});
  if(error)throw error;
  console.log(`Imported ${Math.min(i+batch.length,OPPORTUNITIES.length)} / ${OPPORTUNITIES.length}`);
 }
 console.log('Import complete. Records remain pending_review until individually verified and approved.');
}
main().catch(e=>{console.error(e);process.exit(1)});
