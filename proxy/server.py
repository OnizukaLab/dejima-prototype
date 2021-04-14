import falcon
import sys
import config
sys.dont_write_bytecode = True

app = falcon.API()

METHOD = "two_pl"
if (METHOD=="dev"):
    from dev.execution import Execution
    from dev.propagation import Propagation
    from dev.termination import Termination
    from dev.test import Test
    app.add_route("/execute", Execution())
    app.add_route("/_propagate", Propagation())
    app.add_route("/terminate", Termination())
    app.add_route("/_test", Test())
elif (METHOD=="two_pl"):
    from two_pl.execution import Execution
    from two_pl.propagation import Propagation
    from two_pl.termination import Termination
    from two_pl.test import Test
    app.add_route("/execute", Execution())
    app.add_route("/_propagate", Propagation())
    app.add_route("/terminate", Termination())
    app.add_route("/_test", Test())


if __name__ == "__main__":
    from wsgiref.simple_server import *
    from socketserver import *
    class ThreadingWsgiServer(ThreadingMixIn, WSGIServer):
        pass

    httpd = make_server('0.0.0.0', 8000, app, ThreadingWsgiServer)
    print("serving on port 8000")
    httpd.serve_forever()