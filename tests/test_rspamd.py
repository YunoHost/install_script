
def test_rspamd_running_and_enabled(host):
    rspamd = host.service("rspamd")
    assert rspamd.is_running
    assert rspamd.is_enabled

def test_rspamd_sockets(host):
    assert host.socket("tcp://127.0.0.1:11332").is_listening
    assert host.socket("tcp://127.0.0.1:11333").is_listening
    assert host.socket("tcp://127.0.0.1:11334").is_listening
