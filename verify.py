"""Polite URL reachability check. A successful response does not mean applications are open."""
import requests
from urllib.parse import urlparse
from .pipeline import USER_AGENT, TIMEOUT, SESSION
from .safety import assert_public_https, safe_redirect_url

def verify_url(url: str) -> dict:
    try:
        assert_public_https(url)
        current=url
        for _ in range(4):
            response=SESSION.get(current,allow_redirects=False,timeout=TIMEOUT,headers={"User-Agent":USER_AGENT},stream=True)
            if response.is_redirect or response.is_permanent_redirect:
                current=safe_redirect_url(current,response.headers.get("Location",""))
                continue
            code=response.status_code
            response.close()
            return {"valid":200<=code<400,"status_code":code,"final_url":current,"reason":"reachable" if 200<=code<400 else "http_error"}
        return {"valid":False,"status_code":None,"final_url":current,"reason":"too_many_redirects"}
    except Exception as exc:
        return {"valid":False,"status_code":None,"final_url":None,"reason":str(exc)[:180]}
