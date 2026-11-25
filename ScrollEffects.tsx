'use client';
import { useEffect } from 'react';

export default function ScrollEffects(){
  useEffect(()=>{
    const reduce = window.matchMedia('(prefers-reduced-motion: reduce)').matches;
    const nodes = Array.from(document.querySelectorAll<HTMLElement>('.reveal, .section.container'));
    if(reduce){ nodes.forEach(n=>n.classList.add('is-visible')); return; }
    const observer = new IntersectionObserver((entries)=>{
      entries.forEach(entry=>{
        if(entry.isIntersecting){ entry.target.classList.add('is-visible'); observer.unobserve(entry.target); }
      });
    },{threshold:0.12,rootMargin:'0px 0px -35px 0px'});
    nodes.forEach(n=>observer.observe(n));
    return ()=>observer.disconnect();
  },[]);
  return null;
}
