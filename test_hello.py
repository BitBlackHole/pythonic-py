from hello import hello, more_hello

def test_hello():
    assert "Hi" == hello()

def test_hello2():
    assert "Ho" == more_hello()