'use client';
import {useEffect,useState} from 'react';
const KEY='aventiq-saved';
export function useSavedOpportunities(){
 const [saved,setSaved]=useState<string[]>([]);const [remote,setRemote]=useState(false);
 useEffect(()=>{let live=true;try{setSaved(JSON.parse(localStorage.getItem(KEY)||'[]'))}catch{}fetch('/api/saved').then(async r=>{if(!r.ok)return;const j=await r.json();if(live){setSaved(j.data||[]);setRemote(true)}}).catch(()=>{});return()=>{live=false}},[]);
 const toggleSave=(id:string)=>{setSaved(cur=>{const exists=cur.includes(id);const next=exists?cur.filter(x=>x!==id):[...cur,id];try{localStorage.setItem(KEY,JSON.stringify(next))}catch{}if(remote){fetch(exists?`/api/saved?opportunity_id=${encodeURIComponent(id)}`:'/api/saved',{method:exists?'DELETE':'POST',headers:{'Content-Type':'application/json'},...(exists?{}:{body:JSON.stringify({opportunity_id:id})})}).catch(()=>{})}return next});};
 return {saved,toggleSave,isSaved:(id:string)=>saved.includes(id)};
}
