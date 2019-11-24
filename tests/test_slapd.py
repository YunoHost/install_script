
def test_slapd_running_and_enabled(host):
    ldap = host.service("slapd")
    assert ldap.is_running
    assert ldap.is_enabled

def test_slapd_sockets(host):
    assert host.socket("tcp://636").is_listening
