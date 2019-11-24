
def test_metronome_running_and_enabled(host):
    metronome = host.service("metronome")
    assert metronome.is_running
    assert metronome.is_enabled

def test_metronome_sockets(host):
    # FIXME TODO - no ipv6 ?
    assert host.socket("tcp://0.0.0.0:5222").is_listening
    assert host.socket("tcp://0.0.0.0:5269").is_listening

