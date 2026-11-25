"""Conservative RSS/Atom discovery pipeline. It never publishes guessed or incomplete records."""
from __future__ import annotations
import hashlib, os, re, time
from datetime import datetime, timezone
from urllib.parse import urlparse, urlunparse
from urllib.robotparser import RobotFileParser
import feedparser, requests
from requests.adapters import HTTPAdapter
from urllib3.util.retry import Retry
from bs4 import BeautifulSoup
from dateutil import parser as date_parser
from .safety import assert_public_https, safe_redirect_url

USER_AGENT = os.getenv("WORKER_USER_AGENT", "AventIQOpportunityBot/1.0")
TIMEOUT = int(os.getenv("WORKER_REQUEST_TIMEOUT", "20"))
RETRY = Retry(total=3,connect=3,read=2,status=3,backoff_factor=.6,status_forcelist=(429,500,502,503,504),allowed_methods=frozenset(["GET","HEAD"]),respect_retry_after_header=True)
SESSION = requests.Session()
SESSION.mount("https://",HTTPAdapter(max_retries=RETRY))
_last_host_request = {}
CATEGORIES = {"scholarship", "fellowship", "internship", "grant", "research", "competition", "startup programme", "incubator", "accelerator", "government scheme", "conference", "workshop", "training programme", "job"}

def stable_hash(url: str, title: str) -> str:
    return hashlib.sha256((url.strip().lower() + "|" + re.sub(r"\W+", " ", title.lower()).strip()).encode()).hexdigest()

def check_robots(url: str) -> None:
    assert_public_https(url)
    parsed=urlparse(url); robots=urlunparse((parsed.scheme,parsed.netloc,'/robots.txt','','',''))
    response=SESSION.get(robots,headers={"User-Agent":USER_AGENT},timeout=TIMEOUT,allow_redirects=False)
    if response.status_code==404: return
    if response.is_redirect or response.is_permanent_redirect:
        robots=safe_redirect_url(robots,response.headers.get('Location',''))
        response=SESSION.get(robots,headers={"User-Agent":USER_AGENT},timeout=TIMEOUT,allow_redirects=False)
    if response.status_code>=400: raise ValueError('Could not verify robots.txt permission')
    parser=RobotFileParser(); parser.set_url(robots); parser.parse(response.text.splitlines())
    if not parser.can_fetch(USER_AGENT,url): raise ValueError('robots.txt disallows this source URL')

def throttle(url: str) -> None:
    host=urlparse(url).netloc; now=time.time(); wait=1.0-(now-_last_host_request.get(host,0))
    if wait>0: time.sleep(wait)
    _last_host_request[host]=time.time()

def fetch_feed(url: str):
    assert_public_https(url); check_robots(url); throttle(url)
    current=url
    for _ in range(4):
        response=SESSION.get(current,headers={"User-Agent":USER_AGENT},timeout=TIMEOUT,allow_redirects=False)
        if response.is_redirect or response.is_permanent_redirect:
            current=safe_redirect_url(current,response.headers.get('Location',''))
            continue
        response.raise_for_status()
        return feedparser.parse(response.content)
    raise ValueError('Too many redirects')

def clean_html(value: str) -> str:
    return re.sub(r"\s+", " ", BeautifulSoup(value or "", "html.parser").get_text(" ", strip=True)).strip()

def parse_entry(entry: dict, source_name: str) -> dict:
    title = clean_html(entry.get("title", ""))
    link = entry.get("link", "")
    summary = clean_html(entry.get("summary", ""))
    published = entry.get("published") or entry.get("updated")
    published_at = None
    if published:
        try: published_at = date_parser.parse(published).astimezone(timezone.utc).isoformat()
        except (ValueError, TypeError, OverflowError): pass
    return {
        "title": title or None, "description": summary or None,
        "official_source_url": link or None, "source_name": source_name,
        "external_hash": stable_hash(link, title), "source_published_at": published_at,
        "status": "pending_review",
    }

def run_feed(url: str, source_name: str) -> list[dict]:
    feed = fetch_feed(url)
    if getattr(feed, "bozo", False) and not feed.entries:
        raise ValueError("Feed could not be parsed")
    return [parse_entry(entry, source_name) for entry in feed.entries if entry.get("title") and entry.get("link")]

if __name__ == "__main__":
    import argparse, json
    parser = argparse.ArgumentParser()
    parser.add_argument("--url", required=True); parser.add_argument("--name", default="Configured feed")
    args = parser.parse_args()
    print(json.dumps(run_feed(args.url, args.name), indent=2))

def run_source(url: str, source_name: str, source_type: str = 'rss') -> list[dict]:
    """Fetch one approved RSS/Atom, public JSON/API endpoint, or single public HTML page."""
    if source_type in ('rss','atom'):
        return run_feed(url, source_name)
    assert_public_https(url); check_robots(url); throttle(url)
    current=url
    for _ in range(4):
        response=SESSION.get(current,headers={'User-Agent':USER_AGENT,'Accept':'application/json,text/html;q=0.9,*/*;q=0.5'},timeout=TIMEOUT,allow_redirects=False)
        if response.is_redirect or response.is_permanent_redirect:
            current=safe_redirect_url(current,response.headers.get('Location','')); continue
        response.raise_for_status(); break
    else: raise ValueError('Too many redirects')
    if source_type in ('json','api'):
        payload=response.json()
        entries=payload if isinstance(payload,list) else payload.get('items',payload.get('results',[])) if isinstance(payload,dict) else []
        output=[]
        for row in entries[:250]:
            if not isinstance(row,dict): continue
            title=clean_html(str(row.get('title') or row.get('name') or ''))
            link=row.get('url') or row.get('link') or row.get('official_url')
            if title and isinstance(link,str) and link.startswith('https://'):
                output.append({'title':title,'description':clean_html(str(row.get('description') or row.get('summary') or row.get('content') or '')) or None,'official_source_url':link,'source_name':source_name,'external_hash':stable_hash(link,title),'source_published_at':None,'status':'pending_review'})
        return output
    if source_type=='webpage':
        soup=BeautifulSoup(response.text,'html.parser'); output=[]
        for anchor in soup.select('a[href]')[:250]:
            title=clean_html(anchor.get_text(' ',strip=True))
            try: link=safe_redirect_url(current,anchor.get('href',''))
            except ValueError: continue
            if title and len(title)>5:
                output.append({'title':title,'description':None,'official_source_url':link,'source_name':source_name,'external_hash':stable_hash(link,title),'source_published_at':None,'status':'pending_review'})
        return output
    raise ValueError(f'Unsupported source type: {source_type}')
