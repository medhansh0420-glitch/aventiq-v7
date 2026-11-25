from .pipeline import stable_hash, clean_html, parse_entry
from .scoring import score_record

def test_hash_is_stable():
    assert stable_hash('https://example.org/a', 'Grant') == stable_hash('https://example.org/a', 'Grant')

def test_html_is_cleaned():
    assert clean_html('<p>Hello <b>world</b></p>') == 'Hello world'

def test_missing_critical_fields_block_publish():
    result = score_record({'title':'Grant'}, 1.0, True, False)
    assert result['decision'] == 'pending_review'
    assert 'missing_organization' in result['blockers']
