
def test_yunohost_api_running_and_enabled(host):
    yunohost_api = host.service("yunohost-api")
    assert yunohost_api.is_running
    assert yunohost_api.is_enabled

def test_yunohost_api_sockets(host):
    assert host.socket("tcp://127.0.0.1:6787").is_listening
