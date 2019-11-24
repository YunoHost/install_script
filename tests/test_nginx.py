
def test_nginx_running_and_enabled(host):
    nginx = host.service("nginx")
    assert nginx.is_running
    assert nginx.is_enabled

def test_nginx_sockets(host):
    assert host.socket("tcp://80").is_listening
    assert host.socket("tcp://443").is_listening
