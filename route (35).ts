import { NextResponse } from 'next/server';
import { z } from 'zod';
import { createSupabaseServerClient } from '@/lib/supabase/server';

const idSchema = z.string().uuid();
export async function GET(_request: Request, context: { params: Promise<{ id: string }> }) {
  const { id } = await context.params;
  if (!idSchema.safeParse(id).success) return NextResponse.json({ error: 'Invalid opportunity id' }, { status: 400 });
  try {
    const db = await createSupabaseServerClient();
    const { data, error } = await db.from('opportunities').select('id,legacy_id,title,description,organization,category,subcategory,location,country,eligibility,target_audience,funding_amount,benefits,start_date,deadline,application_url,official_source_url,status,last_verified_at,published_at').eq('id', id).eq('status', 'published').maybeSingle();
    if (error) throw error;
    if (!data) return NextResponse.json({ error: 'Opportunity not found' }, { status: 404 });
    return NextResponse.json({ data });
  } catch (error) {
    console.error('GET /api/opportunities/[id]', error);
    return NextResponse.json({ error: 'Opportunity service is not configured or temporarily unavailable' }, { status: 503 });
  }
}

export async function PATCH(req:Request,context:{params:Promise<{id:string}>}){
 const {requireStaff}=await import('@/lib/auth/guards');const {db,user,response}=await requireStaff();if(response||!user)return response!;
 const {id}=await context.params;if(!idSchema.safeParse(id).success)return NextResponse.json({error:'Invalid opportunity id'},{status:400});
 const schema=z.object({title:z.string().trim().min(3).max(250).optional(),description:z.string().max(8000).nullable().optional(),organization:z.string().max(200).nullable().optional(),category:z.string().max(100).nullable().optional(),deadline:z.string().nullable().optional(),application_url:z.string().url().nullable().optional(),official_source_url:z.string().url().nullable().optional()});
 const p=schema.safeParse(await req.json().catch(()=>null));if(!p.success)return NextResponse.json({error:'Invalid opportunity fields'},{status:400});
 const {data,error}=await db.from('opportunities').update({...p.data,updated_at:new Date().toISOString()}).eq('id',id).select('*').single();if(error)return NextResponse.json({error:'Could not update opportunity'},{status:400});return NextResponse.json({data});
}
