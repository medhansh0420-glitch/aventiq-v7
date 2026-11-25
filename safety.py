"""URL safety checks for the outbound discovery worker."""
import ipaddress, socket
from urllib.parse import urlparse, urljoin

def assert_public_https(url: str) -> None:
    parsed=urlparse(url)
    if parsed.scheme!='https' or not parsed.hostname or parsed.username or parsed.password:
        raise ValueError('Only public HTTPS URLs are allowed')
    host=parsed.hostname.lower()
    if host in {'localhost','localhost.localdomain'} or host.endswith(('.local','.internal','.test')):
        raise ValueError('Local/internal hosts are not allowed')
    try: addresses={item[4][0] for item in socket.getaddrinfo(host,None)}
    except socket.gaierror as exc: raise ValueError('Source host could not be resolved') from exc
    if not addresses: raise ValueError('Source host has no public address')
    for value in addresses:
        ip=ipaddress.ip_address(value)
        if not ip.is_global: raise ValueError('Private or non-global network destinations are not allowed')

def safe_redirect_url(base: str, location: str) -> str:
    target=urljoin(base,location)
    assert_public_https(target)
    return target
