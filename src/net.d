module net;

import std.array;
import std.socket;
import std.variant;
import std.concurrency;

class NetClient {
    private Socket _sock;

    this(string address, ushort port) {
        // just assuming the first address is the correct one...
        _sock = new TcpSocket(getAddress(address, port)[0]);
    }

    void send(T)(T obj) if (NetMsg.allowed!T) {
        auto msg = NetMsg(obj);              // wrap the message in a variant
        auto ret = _sock.send((&msg)[0..1]); // cast as a void*
        assert(ret == msg.sizeof, "Client failed to send network message");
    }

    auto receiveAll() {
        struct Result {
            private Socket _socket;

            this(Socket socket) {
                _socket = socket;
                popFront(); // populate the first message
            }

            NetMsg front;
            bool empty;

            void popFront() {
                auto ret = _socket.receive((&front)[0..1]);
                if (ret > 0) // got a message
                    assert(ret == front.sizeof, "Message length mismatch");
                else
                    empty = true;
            }
        }

        return Result(_sock);
    }
}

class NetServer {
    private Socket _server;
    private Socket[] _clients;

    this(ushort port) {
        _server = new TcpSocket();
        _server.setOption(SocketOptionLevel.SOCKET, SocketOption.REUSEADDR, true);
        _server.bind(new InternetAddress(port));
        _server.blocking = false; // just poll the socket
        _server.listen(1); // 1 is backlog
    }

    bool acceptClient() {
        try {
            _clients ~= _server.accept;
            return true;
        }
        catch return false;
    }

    auto receiveAll() {
        struct Result {
            private typeof(_clients[]) sockets;

            this(typeof(_clients[]) sockets) {
                this.sockets = sockets;
                popFront(); // populate the first message
            }

            NetMsg front;

            bool empty() { return sockets.empty; }

            void popFront() {
                // try to grab a message from the first client in the list
                // whenever a client is empty, pop it
                while (!empty) {
                    auto ret = sockets.front.receive((&front)[0..1]);
                    if (ret > 0) { // got a message
                        assert(ret == front.sizeof, "Message length mismatch");
                        break;
                    }
                    sockets.popFront(); // this client is empty
                }
            }
        }

        return Result(_clients[]);
    }

    void send(T)(T obj) if (NetMsg.allowed!T) {
        auto msg = NetMsg(obj); // wrap the message in a variant

        foreach(sock ; _clients) {
            auto ret = _sock.send((&msg)[0..1]); // cast as a void*
            assert(ret == msg.sizeof, "Server failed to send network message");
        }
    }
}

alias NetMsg = Algebraic!(VelocityMsg, AngleMessage);

struct VelocityMsg {
    float x, y;
}

struct AngleMessage {
    float angle;
}
