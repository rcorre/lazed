module net;

import std.conv;
import std.stdio;
import std.variant;

import derelict.enet.enet;

struct NetClient {
    bool connected;

    ENetHost* host;
    ENetAddress serverAddress;
    ENetPeer* server;

    uint numReceived;

    void start(string address = "127.0.0.1", ushort port = 1234)
    {
        enet_address_set_host(&serverAddress, cast(char*)address);
        serverAddress.port = port;

        host = enet_host_create(null /* create a client host */,
                                1 /* only allow 1 outgoing connection */,
                                2,
                                57600 / 8 /* 56K modem with 56 Kbps downstream bandwidth */,
                                14400 / 8 /* 56K modem with 14 Kbps upstream bandwidth */);

        if (host is null) {
            writeln("Client: An error occured while trying to create an ENet server host");
            return;
        }

        server = enet_host_connect(host, &serverAddress, 2, 42);
        enet_peer_timeout(server, 0, 0, 5000);

        if (server is null) {
            writeln("Client: An error occured while trying to create an ENet server peer");
            return;
        }

        writeln("Client: Started");
        connected = true;
    }

    void update(uint msecs = 0) {
        ENetEvent event;
        int eventStatus = enet_host_service(host, &event, msecs);

        if (eventStatus == 0) return;

        final switch (event.type) {
            case ENET_EVENT_TYPE_NONE:
                break;
            case ENET_EVENT_TYPE_CONNECT:
                onConnect(event);
                break;
            case ENET_EVENT_TYPE_RECEIVE:
                onPacketReceived(event);
                break;
            case ENET_EVENT_TYPE_DISCONNECT:
                onDisconnect(event);
                break;
        }
    }

    void stop() {
        enet_host_destroy(host);
        writefln("Client: Stopped");
    }

    void send(ubyte[] data, ubyte channel = 0)
    {
        ENetPacket* packet = enet_packet_create(data.ptr, data.length,
                ENET_PACKET_FLAG_RELIABLE);
        enet_peer_send(server, channel, packet);
    }

    void send(T)(T msg) {
        send(cast(ubyte[])msg);
    }

    void onConnect(ref ENetEvent event) {
        writefln("Client: Connection to 127.0.0.1:1234 established");

        // Send 3 hello packets.
        foreach(i; 0..3)
        {
            string str = "hello " ~ to!string(i);
            send(cast(ubyte[])str);

            enet_host_flush(host);
        }
    }

    void onPacketReceived(ref ENetEvent event) {
        writefln ("Client: A packet of length %d containing \"%s\" was received from server %s on channel %d",
            event.packet.dataLength,
            (cast(char*)event.packet.data)[0..event.packet.dataLength],
            event.peer.data,
            event.channelID);

        ++numReceived;
        if (numReceived == 3)
            enet_peer_disconnect_later(server, 0);
    }

    void onDisconnect(ref ENetEvent event)
    {
        writefln("Client: disconnected with data %s", event.data);

        // Reset server's information
        event.peer.data = null;

        connected = false;
    }
}

struct NetServer {
    uint numConnected;
    private ulong _nextPeerId;
    bool connected;

    ENetHost* host;
    ENetAddress address;
    ServerSettings settings;

    PeerInfo*[] clients;

    ulong nextPeerId() @property
    {
        scope(exit) ++ _nextPeerId;
        return _nextPeerId;
    }

    // Starts server on port provided in _settings.port
    void start(ServerSettings _settings)
    {
        settings = _settings;

        address.host = ENET_HOST_ANY;
        address.port = settings.port;

        host = enet_host_create(&address,
            settings.maxClients,
            settings.numChannels,
            settings.incomingBandwidth,
            settings.outgoingBandwidth);

        if (host is null) {
            writeln("Server: An error occured while trying to create an ENet server host");
            return;
        }

        connected = true;
    }

    // Updates a server.
    // msecs parameter specifies how long to wait on message before returning
    // On event calls handlers which are located below.
    void update(uint msecs = 0)
    {
        ENetEvent event;
        int eventStatus = enet_host_service(host, &event, msecs);

        if (eventStatus == 0) return;

        final switch (event.type)
        {
            case ENET_EVENT_TYPE_NONE:
                break;
            case ENET_EVENT_TYPE_CONNECT:
                onConnect(event);
                break;
            case ENET_EVENT_TYPE_RECEIVE:
                onPacketReceived(event);
                break;
            case ENET_EVENT_TYPE_DISCONNECT:
                onDisconnect(event);
                break;
        }
    }

    // ditto but to all clients
    void send(ubyte[] data, ubyte channel = 0) {
        ENetPacket *packet = enet_packet_create(data.ptr, data.length,
                    ENET_PACKET_FLAG_RELIABLE);
        enet_host_broadcast(host, channel, packet);
    }

    // ditto but resends existing packet
    void send(ENetPacket* packet, ubyte channel = 0) {
        enet_host_broadcast(host, channel, packet);
    }

    //
    void stop()
    {
        enet_host_destroy(host);
        writefln("Server: Stopped");
    }

    private:
    void onConnect(ref ENetEvent event)
    {
        writefln("Server: A new client connected from %(%s.%):%s",
            *cast(ubyte[4]*)(&event.peer.address.host),
            event.peer.address.port);

        PeerInfo* client = new PeerInfo(nextPeerId, event.peer);
        clients ~= client;
        event.peer.data = cast(void*)client;
        enet_peer_timeout(event.peer, 0, 0, 2000);

        ++numConnected;
    }

    void onPacketReceived(ref ENetEvent event)
    {
        writefln ("Server: A packet of length %d containing \"%s\" was received from client %s on channel %d",
            event.packet.dataLength,
            (cast(char*)event.packet.data)[0..event.packet.dataLength],
            (cast(PeerInfo*)event.peer.data).id,
            event.channelID);

        // Lets broadcast this message to all
        // packet is automatically destroyed by broadcast
        send(event.packet);
    }

    void onDisconnect(ref ENetEvent event)
    {
        writefln("Server: client %s disconnected", (cast(PeerInfo*)event.peer.data).id);

        // Reset client's information
        event.peer.data = null;
        --numConnected;

        if (numConnected == 0)
            connected = false;
    }
}

struct PeerInfo
{
    ulong id;
    ENetPeer* peer;
}

struct ServerSettings
{
    ushort port;
    size_t maxClients;
    size_t numChannels;
    uint incomingBandwidth;
    uint outgoingBandwidth;
}
