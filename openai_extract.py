"""Structured extraction. Missing facts remain null; model output is always a review candidate."""
from __future__ import annotations
import os, json
from openai import OpenAI
from pydantic import BaseModel, Field

class OpportunityExtraction(BaseModel):
    title: str | None = None
    description: str | None = None
    organization: str | None = None
    category: str | None = None
    subcategory: str | None = None
    location: str | None = None
    country: str | None = None
    eligibility: str | None = None
    target_audience: str | None = None
    funding_amount: str | None = None
    benefits: str | None = None
    start_date: str | None = None
    deadline: str | None = None
    application_url: str | None = None
    required_documents: list[str] = Field(default_factory=list)
    application_instructions: str | None = None
    missing_fields: list[str] = Field(default_factory=list)

def extract_opportunity(title: str, summary: str, source_url: str) -> dict:
    key = os.getenv('OPENAI_API_KEY')
    if not key: raise RuntimeError('OPENAI_API_KEY is not configured')
    client = OpenAI(api_key=key)
    prompt = ('Extract only facts explicitly supported by the supplied source. Never infer eligibility, deadlines, funding, '
              'or open/closed status. Use null for missing values and list missing critical fields. Source URL: '+source_url+
              '\nTitle: '+title+'\nContent: '+summary[:12000])
    result = client.responses.parse(model=os.getenv('OPENAI_MODEL','gpt-4.1-mini'), input=[{'role':'system','content':'You extract opportunity facts conservatively. Never invent facts.'},{'role':'user','content':prompt}], text_format=OpportunityExtraction)
    parsed = result.output_parsed
    if not parsed: raise ValueError('Model returned no structured extraction')
    return parsed.model_dump()
