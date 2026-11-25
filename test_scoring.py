from workers.discovery.scoring import score_record

def test_missing_critical_fields_block_publish():
    result=score_record({'title':'Research fellowship'},1.0,True,False)
    assert result['decision']=='pending_review'
    assert 'missing_organization' in result['blockers']
    assert 'missing_application_url' in result['blockers']
    assert 'missing_deadline' in result['blockers']

def test_duplicate_blocks_publish_even_with_complete_fields():
    record={'title':'A','description':'B','organization':'C','category':'Grant','official_source_url':'https://example.org','application_url':'https://example.org/app','deadline':'2027-01-01'}
    result=score_record(record,1.0,True,True)
    assert result['decision']=='pending_review'
    assert 'possible_duplicate' in result['blockers']

def test_low_confidence_stays_pending():
    record={'title':'A','description':'B','organization':'C','category':'Grant','official_source_url':'https://example.org','application_url':'https://example.org/app','deadline':'2027-01-01'}
    result=score_record(record,.1,False,False)
    assert result['decision']=='pending_review'
