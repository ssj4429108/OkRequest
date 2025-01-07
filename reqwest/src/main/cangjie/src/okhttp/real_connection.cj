/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2022-2024. All rights resvered.
 */

/**
 * @file
 * The file declares the Connection class.
 */

package ohos_app_cangjie_OkRequest.okhttp

/**
 * The class is Connection
 * @author guo_tingtingtekla,luoyukai4
 * @since 0.29.3
 */
public class Connection {
    /* var member connectionPool type is ConnectionPool */
    private let connectionPool: ConnectionPool

    /* var member transmitters type is ArrayList<Transmitter> */
    var transmitters: ArrayList<Transmitter> = ArrayList<Transmitter>()
    private var rawSocket: Option<SocketClient> = Option<SocketClient>.None

    /* var member socket type is Option<SocketClient> */
    var socket: Option<OKSocket> = Option<OKSocket>.None

    /* var member route type is Route */
    let route: Route

    /*If true, no new exchanges can be created on this connection.*/
    var noNewExchanges: Bool = false

    private var allocationLimit: Int64 = 1

    private var protocol: Protocol = HTTP_1_1

    private var h2conn: Option<H2Connection> = None

    var idleAtNanos: DateTime = DateTime.ofEpoch(second: 0, nanosecond: 999999999)

    var successCount: Int64 = 0

    var routeFailureCount: Int64 = 0

    private var sink: ?BufferedOutputStream<OutputStream> = None

    private var source: Option<OkBuffer> = Option<OkBuffer>.None

    private var refusedStreamCount: Int64 = 0

    /**
     * The Function is init constructor
     *
     * @param connectionPool of ConnectionPool
     * @param route of Route
     * @since 0.29.3
     */
    public init(connectionPool: ConnectionPool, route: Route) {
        this.connectionPool = connectionPool
        this.route = route
    }

    /**
     * The Function is getProtocol
     *
     * @return Type of Protocol
     * @since 0.30.4
     */
    public func getProtocol(): Protocol {
        return protocol
    }

    /**
     * The Function is getTransmitters
     *
     * @return Type of ArrayList<Transmitter>
     * @since 0.29.3
     */
    public func getTransmitters(): ArrayList<Transmitter> {
        return transmitters
    }

    /**
     * The Function is noExchanges
     *
     * @return Type of Unit
     * @since 0.30.4
     */
    public func noExchanges(): Unit {
        synchronized(connectionPool.mutex) {
            noNewExchanges = true
        }
    }

    /**
     * The Function is getSocket
     *
     * @return Type of Option<Socket>
     * @since 0.29.3
     */
    public func getSocket(): Option<OKSocket> {
        return socket
    }

    /**
     * The Function is getRoute
     *
     * @return Type of Route
     * @since 0.29.3
     */
    public func getRoute(): Route {
        return route
    }

    /**
     * The Function is isEligible
     *
     * @param address of Address
     *
     * @return Type of Bool
     * @since 0.29.3
     */
    func isEligible(address: Address, routeSelector: Option<RouteSelector>): Bool {
        if (transmitters.size >= allocationLimit || noNewExchanges) {
            return false
        }

        if (this.route.getAddress() != address) {
            return false
        }

        if (address.getUrl().hostName == route.getAddress().getUrl().hostName) {
            return true
        }

        // HTTP/2.
        match (h2conn) {
            case Some(_) => ()
            case None => return false
        }

        //any same address
        match (routeSelector) {
            case Some(rs) =>
                if (!routeMatchesAny(rs)) {
                    return false
                }
                ()
            case None => return false
        }
        return true
    }

    public func isHealthy(): Bool {
        if (socket.getOrThrow().isClosed()) {
            return false
        }
        match (h2conn) {
            case Some(h2con) => return h2con.isHealthy()
            case None => ()
        }
        return true
    }

    private func routeMatchesAny(routeSelector: RouteSelector): Bool {
        let routeSelectorSize = routeSelector.getAll()
        for (i in 0..routeSelectorSize.size) {
            if (route.inetSocketAddress == routeSelectorSize[i].inetSocketAddress) {
                return true
            }
        }
        return false
    }

    /**
     * The Function is isMultiplexed
     *
     * @return Type of Bool
     * @since 0.29.3
     */
    public func isMultiplexed(): Bool {
        match (h2conn) {
            case Some(_) => return true
            case None => return false
        }
    }

    /**
     * The Function is connect
     *
     * @since 0.29.3
     */
    public func connect(
        connectTimeout: Option<Duration>,
        readTimeout: Option<Duration>,
        writeTimeout: Option<Duration>,
        _: Bool, // connectionRetryEnabled
        eventListener: EventListener,
        call: Call
    ) {
        checkSslSocket()

        try {
            establishProtocol(connectTimeout, readTimeout, writeTimeout, eventListener, call)
        } catch (e: HttpException) {
            Util.closeQuietly(rawSocket)
            Util.closeQuietly(socket)
            socket = None
            h2conn = None
            sink = None
            source = None
            h2conn = None
            protocol = HTTP_1_1
            eventListener.connectFailed(call, route.inetSocketAddress, protocol, e)
            throw RouteException("${e.message}", e)
        }

        match (h2conn) {
            case Some(h2) => onSettings(h2)
            case None => ()
        }
    }

    public func onSettings(h2: H2Connection) {
        synchronized(connectionPool.mutex) {
            allocationLimit = h2.getMaxConcurrentStreams()
        }
    }

    private func checkSslSocket(): Unit {
        match (route.getAddress().getTlsConfig()) {
            case None => ()
            case Some(_) => if (route.getAddress().getProtocols().contains(Protocol.H2_PRIOR_KNOWLEDGE.toString())) {
                throw RouteException(
                    "H2_PRIOR_KNOWLEDGE cannot be used with HTTPS",
                    HttpException("H2_PRIOR_KNOWLEDGE cannot be used with HTTPS")
                )
            }
        }
    }

    /*
     * The Function is connectSocket
     *
     * @since 0.29.3
     */
    private func connectSocket(connectTimeout: ?Duration, readTimeout: ?Duration, writeTimeout: ?Duration): TcpSocket {
        let socketAddress: SocketAddress = route.inetSocketAddress
        try {
            let s = TcpSocket(socketAddress.hostAddress, socketAddress.port)
            s.readTimeout = readTimeout
            s.writeTimeout = writeTimeout
            s.connect(timeout: connectTimeout)
            rawSocket = SocketC(s)
            return s
        } catch (e1: SocketException) {
            throw ConnectException("Failed to connect to ${socketAddress}", e1)
        } catch (e2: SocketTimeoutException) {
            throw ConnectException("connect to ${socketAddress} time out", e2)
        }
    }

    private func establishProtocol(
        connectTimeout: Option<Duration>,
        readTimeout: Option<Duration>,
        writeTimeout: Option<Duration>,
        eventListener: EventListener,
        call: Call
    ) {
        match (route.getAddress().getTlsConfig()) {
            case None =>
                eventListener.connectStart(call, route.inetSocketAddress)
                connectSocket(connectTimeout, readTimeout, writeTimeout)
                let client = OKSocket(rawSocket.getOrThrow(), readTimeout, writeTimeout)
                socket = client
                sink = BufferedOutputStream<OutputStream>(client)
                source = OkBuffer(client)
                if (route.getAddress().getProtocols().contains(Protocol.H2_PRIOR_KNOWLEDGE.toString())) {
                    this.protocol = H2_PRIOR_KNOWLEDGE
                    startHttp2()
                }
                eventListener.connectEnd(call, route.inetSocketAddress, protocol)
            case Some(tls) =>
                //ALPN
                eventListener.secureConnectStart(call)
                connectTls(connectTimeout, readTimeout, writeTimeout)
                eventListener.secureConnectEnd(call, tls)
                if (protocol.toString() == "h2") {
                    startHttp2()
                }
        }
    }

    private func startHttp2() {
        match (socket) {
            case Some(s) =>
                let cc = H2Connection(s.client, sink.getOrThrow(), source.getOrThrow(), listener: this)
                cc.start()
                h2conn = cc
            case None => ()
        }
    }

    private func connectTls(
        connectTimeout: Option<Duration>,
        readTimeout: Option<Duration>,
        writeTimeout: Option<Duration>
    ) {
        let address = route.getAddress()
        var cfg = route.getAddress().getTlsConfig().getOrThrow()
        cfg.alpnProtocolsList = collectArray(address.getProtocols().iterator())
        try {
            let tcpSocket = connectSocket(connectTimeout, readTimeout, writeTimeout)
            let client = TlsSocket.client(tcpSocket, clientConfig: cfg)
            client.readTimeout = readTimeout
            client.writeTimeout = writeTimeout
            client.handshake()
            let realSocket = OKSocket(TlsC(client), readTimeout, writeTimeout)
            let aplnSelected: String = client.alpnProtocolName.getOrThrow()
            socket = realSocket
            sink = BufferedOutputStream<OutputStream>(realSocket)
            source = OkBuffer(realSocket)
            if (aplnSelected != "") {
                protocol = Protocol.get(aplnSelected)
            }
        } catch (e: TlsException) {
            throw ConnectException("${e.message}", e)
        }
    }

    /**
     * The Function is newCodec
     *
     * @param client of HttpClient
     * @param chain of Chain
     *
     * @return Type of ExchangeCodec
     * @since 0.29.3
     */
    func newCodec(client: HttpClient, _: Chain): ExchangeCodec {
        match (h2conn) {
            case None => Http1ExchangeCodec(client, this, this.source.getOrThrow(), this.sink.getOrThrow())
            case Some(_) => Http2ExchangeCodec(client, this, h2conn.getOrThrow())
        }
    }

    /**
     * The Function is cancel
     *
     * @return Type of Unit
     * @since 0.30.4
     */
    public func cancel(): Unit {
        Util.closeQuietly(socket)
    }

    func trackFailure(e: HttpException): Unit {
        synchronized(connectionPool.mutex) {
            if (e is StreamResetException) {
                let errorCode = (e as StreamResetException).getOrThrow().errorCode
                if (errorCode.getCode() == REFUSED_STREAM.getCode()) {
                    //  Stop using this connection on the 2nd REFUSED_STREAM error.
                    refusedStreamCount++
                    if (refusedStreamCount > 1) {
                        noNewExchanges = true
                        routeFailureCount++
                    }
                } else if (errorCode.getCode() != CANCEL.getCode()) {
                    noNewExchanges = true
                    routeFailureCount++
                }
            } else if (!isMultiplexed() || e is ConnectionShutdownException) {
                noNewExchanges = true
                if (successCount == 0) {
                    connectionPool.connectFailed(route)
                }
                routeFailureCount++
            }
        }
    }
}
