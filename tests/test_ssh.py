
def test_ssh_running_and_enabled(host):
    ssh = host.service("ssh")
    assert ssh.is_running
    assert ssh.is_enabled

def test_ssh_sockets(host):
    assert host.socket("tcp://22").is_listening
