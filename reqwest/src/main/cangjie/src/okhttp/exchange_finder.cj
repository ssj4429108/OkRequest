/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2022-2024. All rights resvered.
 */

/**
 * @file
 * The file declares the ExchangeFinder class.
 */

package ohos_app_cangjie_OkRequest.okhttp

/**
 * The class is ExchangeFinder
 * @author guo_tingtingtekla,luoyukai4
 * @since 0.29.3
 */
class ExchangeFinder {
    /* var member transmitter type is Transmitter */
    private var transmitter: Transmitter

    /* var member address type is Address */
    private var address: Address

    /* var member call type is Call */
    private var call: Call

    /* var member connectionPool type is ConnectionPool */
    private var connectionPool: ConnectionPool

    /* var member routeSelector type is RouteSelector */
    private var routeSelector: RouteSelector

    /* var member connectingConnection type is Option<Connection> */
    private var connectingConnection: Option<Connection> = None
    private var hasStreamFailure: Bool = false
    private var nextRouteToTry: Option<Route> = None
    private let eventListener: EventListener

    /**
     * The Function is init constructor
     *
     * @param transmitter of Transmitter
     * @param connectionPool of ConnectionPool
     * @param address of Address
     * @param call of Call
     * @since 0.29.3
     */
    init(
        transmitter: Transmitter,
        connectionPool: ConnectionPool,
        address: Address,
        call: Call,
        eventListener: EventListener
    ) {
        this.transmitter = transmitter
        this.connectionPool = connectionPool
        this.eventListener = eventListener
        this.call = call
        this.address = address
        this.routeSelector = RouteSelector(address, connectionPool.routeDatabase, call, eventListener)
    }

    /**
     * The Function is find
     *
     * @param client of HttpClient
     * @param chain of Chain
     * @param doExtensiveHealthChecks of Bool
     *
     * @return Type of ExchangeCodec
     * @since 0.29.3
     */
    public func find(client: HttpClient, chain: Chain, _: Bool): ExchangeCodec {
        let connectTimeout: Option<Duration> = client.getConnectTimeout()
        let readTimeout: Option<Duration> = client.getReadTimeout()
        let writeTimeout: Option<Duration> = client.getWriteTimeout()
        let connectionRetryEnabled: Bool = client.getRetryOnConnectionFailure()
        try {
            let conn = findHealthyConnection(connectTimeout, readTimeout, writeTimeout, connectionRetryEnabled)
            return conn.getOrThrow().newCodec(client, chain)
        } catch (e: RouteException) {
            trackFailure()
            throw e
        } catch (e1: HttpException) {
            trackFailure()
            throw RouteException(e1.message, e1)
        }
    }

    /*
     * The Function is findHealthyConnection
     *
     * @return Type of Connection
     * @since 0.29.3
     */
    private func findHealthyConnection(
        connectTimeout: Option<Duration>,
        readTimeout: Option<Duration>,
        writeTimeout: Option<Duration>,
        connectionRetryEnabled: Bool
    ): Option<Connection> {
        while (true) {
            let candidate: Connection = findConnection(connectTimeout, readTimeout, writeTimeout, connectionRetryEnabled
            )
            synchronized(connectionPool.mutex) {
                if (candidate.successCount == 0 && !candidate.isMultiplexed()) {
                    return candidate
                }
            }
            if (!candidate.isHealthy()) {
                candidate.noExchanges()
            }
            return candidate
        }
        return Option<Connection>.None
    }

    /*
     * The Function is findConnection
     *
     * @return Type of Connection
     * @since 0.29.3
     */
    private func findConnection(
        connectTimeout: Option<Duration>,
        readTimeout: Option<Duration>,
        writeTimeout: Option<Duration>,
        connectionRetryEnabled: Bool
    ): Connection {
        let tuple: (Option<OKSocket>, Option<Connection>, Option<Route>) = firstGetConn()
        var toClose: Option<OKSocket> = tuple[0]
        var result: Option<Connection> = tuple[1]
        var selectedRoute: Option<Route> = tuple[2]
        Util.closeQuietly(toClose)
        match (result) {
            case Some(r) => return r
            case None => ()
        }

        let newRouteSelection: Bool = !has(selectedRoute)

        synchronized(connectionPool.mutex) {
            if (transmitter.isCanceled()) {
                throw HttpException("Canceled")
            }
            if (newRouteSelection) {
                if (connectionPool.transmitterAcquirePooledConnection(
                    address,
                    transmitter,
                    routeSelector,
                    requireMultiplexed: false
                )) {
                    result = transmitter.connection
                    return result.getOrThrow()
                }
            }
        }

        if (!has(selectedRoute)) {
            selectedRoute = routeSelector.next()
        }

        result = Connection(connectionPool, selectedRoute.getOrThrow())
        connectingConnection = result
        var conn: Connection = result.getOrThrow()
        conn.connect(connectTimeout, readTimeout, writeTimeout, connectionRetryEnabled, eventListener, call)
        connectionPool.routeDatabase.connected(conn.route)
        var socket: Option<OKSocket> = None
        synchronized(connectionPool.mutex) {
            connectingConnection = None
            if (connectionPool.transmitterAcquirePooledConnection(
                address,
                transmitter,
                routeSelector,
                requireMultiplexed: true
            )) {
                conn.noNewExchanges = true
                socket = conn.getSocket()
                conn = transmitter.connection.getOrThrow()
                nextRouteToTry = selectedRoute
            } else {
                connectionPool.put(conn)
                transmitter.acquireConnectionNoEvents(result)
            }
        }
        Util.closeQuietly(socket)
        return result.getOrThrow()
    }

    func firstGetConn(): (Option<OKSocket>, Option<Connection>, Option<Route>) {
        var toClose: Option<OKSocket>
        var result: Option<Connection> = Option<Connection>.None
        var selectedRoute: Option<Route> = None
        synchronized(connectionPool.mutex) {
            if (transmitter.isCanceled()) {
                throw HttpException("Transmitter has Canceled")
            }
            hasStreamFailure = false
            match (transmitter.connection) {
                case Some(conn) =>
                    result = transmitter.connection
                    if (conn.noNewExchanges) {
                        toClose = transmitter.releaseConnectionNoEvents()
                    } else {
                        toClose = Option<OKSocket>.None
                    }
                case _ => toClose = Option<OKSocket>.None
            }

            //Attempt to get a connection from the pool first time .
            match (result) {
                case Some(_) => ()
                case None => if (connectionPool.transmitterAcquirePooledConnection(
                    address,
                    transmitter,
                    Option<RouteSelector>.None
                )) {
                    result = transmitter.connection
                } else {
                    match (nextRouteToTry) {
                        case Some(route) =>
                            selectedRoute = route
                            nextRouteToTry = None
                        case None => if (retryCurrentRoute()) {
                            selectedRoute = transmitter.connection.getOrThrow().route
                        }
                    }
                }
            }
        }
        return (toClose, result, selectedRoute)
    }

    func getHasStreamFailure(): Bool {
        synchronized(connectionPool.mutex) {
            return hasStreamFailure
        }
    }

    func getConnectingConnection(): Option<Connection> {
        return connectingConnection
    }

    func hasRouteToTry(): Bool {
        synchronized(connectionPool.mutex) {
            match (nextRouteToTry) {
                case Some(_) => return true
                case None => ()
            }
            if (retryCurrentRoute()) {
                nextRouteToTry = transmitter.connection.getOrThrow().route
                return true
            }
            return routeSelector.hasNext()
        }
    }

    private func retryCurrentRoute(): Bool {
        match (transmitter.connection) {
            case Some(conn) => if (conn.routeFailureCount == 0 && Util.sameConnection(
                conn.route.getAddress().getUrl(),
                address.getUrl()
            )) {
                return true
            } else {
                return false
            }
            case None => return false
        }
    }
    func trackFailure(): Unit {
        synchronized(connectionPool.mutex) {
            hasStreamFailure = true
        }
    }
}

/**
 * The class is Exchange
 * @author guo_tingtingtekla,luoyukai4
 * @since 0.29.3
 */
public class Exchange {
    /** var member transmitter type is Transmitter */
    let transmitter: Transmitter

    /** var member call type is Call */
    let call: Call

    /** var member finder type is ExchangeFinder */
    let finder: ExchangeFinder

    /** var member codec type is ExchangeCodec */
    let codec: ExchangeCodec
    let eventListener: EventListener

    /**
     * The Function is init constructor
     *
     * @param transmitter of Transmitter
     * @param call of Call
     * @param finder of ExchangeFinder
     * @param codec of ExchangeCodec
     * @since 0.29.3
     */
    init(
        transmitter: Transmitter,
        call: Call,
        finder: ExchangeFinder,
        codec: ExchangeCodec,
        eventListener: EventListener
    ) {
        this.transmitter = transmitter
        this.call = call
        this.finder = finder
        this.codec = codec
        this.eventListener = eventListener
    }

    /**
     * The Function is readResponseHeaders
     *
     * @return Type of ResponseBuilder
     * @since 0.29.3
     */
    public func readResponseHeaders(expectContinue: Bool): Option<ResponseBuilder> {
        try {
            let result: Option<ResponseBuilder> = codec.readResponseHeaders(expectContinue)
            match (result) {
                case Some(r) => initExchange(r, this)
                case None => ()
            }
            return result
        } catch (e: HttpException) {
            eventListener.responseFailed(call, e)
            trackFailure(e)
            throw e
        }
    }

    private func initExchange(respb: ResponseBuilder, exchange: Exchange): Unit {
        respb.initExchange(exchange)
    }

    /**
     * The Function is openResponseBody
     *
     * @return Type of ResponseBody
     * @since 0.29.3
     */
    public func openResponseBody(response: Response): ResponseBody {
        try {
            eventListener.responseBodyStart(call)
            let contentTypeString: String = response.getHeader("Content-Type", "")
            let contentLength: Int64 = codec.reportedContentLength(response)
            let source = codec.openResponseBodySource(response)
            return ResponseBody(contentTypeString, contentLength, ResponseBodySource(source, this, contentLength))
        } catch (e: HttpException) {
            eventListener.responseFailed(call, e)
            trackFailure(e)
            throw e
        }
    }

    func responseHeadersStart(): Unit {
        eventListener.responseHeadersStart(call)
    }

    func responseHeadersEnd(response: Response): Unit {
        eventListener.responseHeadersEnd(call, response)
    }

    public func getConnection(): Connection {
        return codec.getConnection()
    }

    public func cancel() {
        codec.cancel()
    }

    public func detachWithViolence() {
        cancel()
        transmitter.exchangeMessageDone(this, true, true)
    }

    public func noNewExchangesOnConnection(): Unit {
        codec.getConnection().noExchanges()
    }

    public func noRequestBody(): Unit {
        transmitter.exchangeMessageDone(this, true, false)
    }

    public func getTrailers() {
        return codec.getTrailers()
    }

    public func createRequestBody(request: Request): Sink {
        let contentLength = request.getBody().getOrThrow().getContentLength()
        eventListener.requestBodyStart(call)
        let rawRequestBody: Sink
        if (contentLength != -1) {
            rawRequestBody = RealBufferSink(codec.createRequestBody(request))
        } else {
            rawRequestBody = codec.createRequestBody(request)
        }

        return RequestBodySink(rawRequestBody, contentLength, this)
    }

    public func writeRequestHeaders(request: Request): Unit {
        try {
            eventListener.requestHeadersStart(call)
            codec.writeRequestHeaders(request)
            eventListener.requestHeadersEnd(call)
        } catch (e: SocketException | IOException) {
            eventListener.requestFailed(call, HttpException(e.message))
            trackFailure(HttpException(e.message))
            throw e
        }
    }

    public func flushRequest(): Unit {
        try {
            codec.flushRequest()
        } catch (e: SocketException | IOException) {
            trackFailure(HttpException(e.message))
            throw e
        }
    }

    public func finishRequest(): Unit {
        try {
            codec.finishRequest()
        } catch (e: SocketException | IOException) {
            trackFailure(HttpException(e.message))
            throw e
        }
    }

    func bodyComplete(bytesRead: Int64, responseDone: Bool, requestDone: Bool, exception: Option<HttpException>): Unit {
        match (exception) {
            case Some(e) => trackFailure(e)
            case None => ()
        }

        if (requestDone) {
            if (has(exception)) {
                eventListener.requestFailed(call, exception.getOrThrow())
            } else {
                eventListener.requestBodyEnd(call, bytesRead)
            }
        }

        if (responseDone) {
            if (has(exception)) {
                eventListener.responseFailed(call, exception.getOrThrow())
            } else {
                eventListener.responseBodyEnd(call, bytesRead)
            }
        }

        transmitter.exchangeMessageDone(this, requestDone, responseDone)
    }

    func trackFailure(exception: HttpException): Unit {
        finder.trackFailure()
        codec.getConnection().trackFailure(exception)
    }
}
