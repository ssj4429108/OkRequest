/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2022-2024. All rights resvered.
 */

/**
 * @file
 * The file declares the Call interface.
 */

package ohos_app_cangjie_reqwest.okhttp

/**
 * The class is RealCall inherited from Call
 * @author guo_tingtingtekla,luoyukai4
 * @since 0.29.3
 */
class RealCall <: Call {
    public var mutex: Monitor = Monitor()

    /** var member forWebSocket type is Bool */
    public var forWebSocket: Bool

    /** var member client type is HttpClient */
    var client: HttpClient

    /** var member originalRequest type is Request */
    public var originalRequest: Request

    /** var member transmitter type is Option<Transmitter> */
    public var transmitter: Option<Transmitter> = Option<Transmitter>.None
    private var executed: Bool = false

    /*
     * The Function is init constructor
     *
     * @param client of HttpClient
     * @param originalRequest of Request
     * @param forWebSocket of Bool
     * @since 0.29.3
     */
    private init(client: HttpClient, originalRequest: Request, forWebSocket: Bool) {
        this.client = client
        this.originalRequest = originalRequest
        this.forWebSocket = forWebSocket
    }

    /**
     * The Function is getRequest
     *
     * @return Type of Request
     * @since 0.29.3
     */
    public func getRequest(): Request {
        return originalRequest
    }

    /**
     * The Function is getTransmitter
     *
     * @return Type of Transmitter
     * @since 0.29.3
     */
    public func getTransmitter(): Transmitter {
        return transmitter.getOrThrow()
    }

    /**
     * The Function is execute
     *
     * @return Type of Response
     * @since 0.29.3
     */
    public func execute(): Response {
        synchronized(this.mutex) {
            if (executed) {
                throw HttpException("Already Executed")
            }
            executed = true
            client.getEventListener().callStart(this)
        }
        try {
            client.getDispatcher().executed(this)
            return getResponseWithInterceptorChain()
        } finally {
            client.getDispatcher().finished(this)
        }
    }

    /**
     * The Function is enqueue
     *
     * @param responseCallback of Callback
     *
     * @return Type of Unit
     * @since 0.29.3
     */
    public func enqueue(responseCallback: Callback): Unit {
        synchronized(this.mutex) {
            if (executed) {
                throw HttpException("Already Executed")
            }
        }
        executed = true
        client.getEventListener().callStart(this)
        client.getDispatcher().enqueue(AsyncCall(responseCallback, this))
    }

    /**
     * The Function is cancel
     *
     * @return Type of Unit
     * @since 0.29.3
     */
    public func cancel(): Unit {
        getTransmitter().cancel()
    }

    /**
     * The Function is isExecuted
     *
     * @return Type of Bool
     * @since 0.29.3
     */
    public func isExecuted(): Bool {
        return executed
    }

    /**
     * The Function is isCanceled
     *
     * @return Type of Bool
     * @since 0.29.3
     */
    public func isCanceled(): Bool {
        return getTransmitter().isCanceled()
    }

    /**
     * The Function is clone
     *
     * @return Type of Call
     * @since 0.29.3
     */
    public func clone(): Call {
        return RealCall.newRealCall(client, originalRequest, forWebSocket)
    }

    /**
     * The Function is getResponseWithInterceptorChain
     *
     * @return Type of Response
     * @since 0.29.3
     */
    func getResponseWithInterceptorChain(): Response {
        let interceptors: ArrayList<Interceptor> = ArrayList<Interceptor>()
        interceptors.appendAll(client.getInterceptors())
        interceptors.append(RetryAndFollowUpInterceptor(client))
        interceptors.append(BridgeInterceptor(client.getCookieJar()))
        interceptors.append(CacheInterceptor(client.getCache()))
        interceptors.append(ConnectInterceptor(client))

        if (!forWebSocket) {
            interceptors.appendAll(client.getNetworkInterceptors())
        }

        interceptors.append(CallServerInterceptor(forWebSocket))
        let chain: Chain = Chain(
            interceptors,
            getTransmitter(),
            0,
            originalRequest,
            this,
            Option<Exchange>.None,
            client.getConnectTimeout(),
            client.getReadTimeout(),
            client.getWriteTimeout()
        )
        let response: Response
        var calledNoMoreExchanges = false

        try {
            response = chain.proceed(originalRequest)
            if (getTransmitter().isCanceled()) {
                match (response.getBody()) {
                    case Some(body) => body.close()
                    case None => ()
                }
            }
            return response
        } catch (e: HttpException) {
            calledNoMoreExchanges = true
            getTransmitter().noMoreExchanges()
            throw e
        } finally {
            let transmitter = getTransmitter()
            transmitter.ref = false

            if (has(transmitter.connection)) {
                transmitter.connection.getOrThrow().idleAtNanos = DateTime.now()
            }

            if (!calledNoMoreExchanges) {
                getTransmitter().noMoreExchanges()
            }
        }
    }

    /**
     * The Function is newRealCall
     *
     * @param client of HttpClient
     * @param originalRequest of Request
     * @param forWebSocket of Bool
     *
     * @return Type of RealCall
     * @since 0.29.3
     */
    static func newRealCall(client: HttpClient, originalRequest: Request, forWebSocket: Bool): RealCall {
        let call: RealCall = RealCall(client, originalRequest, forWebSocket)
        call.transmitter = Transmitter(client, call)
        return call
    }
}

/**
 * The class is AsyncCall
 * @author guo_tingtingtekla,luoyukai4
 * @since 0.29.3
 */
class AsyncCall {
    /** var member callsPerHost type is AtomicInt64 */
    public var callsPerHost: AtomicInt64Class = AtomicInt64Class()

    /* let member responseCallback type is Callback */
    private let responseCallback: Callback

    /* let member realCall type is RealCall */
    private let realCall: RealCall

    /*
     * The Function is init constructor
     *
     * @param responseCallback of Callback
     * @param realCall of RealCall
     * @since 0.29.3
     */
    init(responseCallback: Callback, realCall: RealCall) {
        this.responseCallback = responseCallback
        this.realCall = realCall
    }

    func getCallsPerHost(): AtomicInt64Class {
        return callsPerHost
    }

    /*
     * The Function is reuseCallsPerHostFrom
     *
     * @param other of AsyncCall
     *
     * @return Type of Unit
     * @since 0.29.3
     */
    func reuseCallsPerHostFrom(other: AsyncCall): Unit {
        this.callsPerHost = other.callsPerHost
    }

    /*
     * The Function is get
     *
     * @return Type of RealCall
     * @since 0.29.3
     */
    func get(): RealCall {
        return realCall
    }

    /*
     * The Function is host
     *
     * @return Type of String
     * @since 0.29.3
     */
    func host(): String {
        return realCall.getRequest().getUrl().hostName
    }

    public func cancel() {
        realCall.cancel()
    }

    /*
     * The Function is executeOn
     *
     * @since 0.29.3
     */
    public func executeOn(): Unit {
        spawn {
            execute()
        }
    }

    /*
     * The Function is execute
     *
     * @since 0.29.3
     */
    public func execute(): Unit {
        var signalledCallback: Bool = false

        try {
            let response: Response = realCall.getResponseWithInterceptorChain()
            signalledCallback = true
            responseCallback.onResponse(realCall, response)
        } catch (e: HttpException) {
            if (!signalledCallback) {
                responseCallback.onFailure(realCall, e)
            }
        } catch (e: Exception) {
            cancel()
            if (!signalledCallback) {
                responseCallback.onFailure(realCall, e)
            }
        } finally {
            realCall.client.getDispatcher().finished(this)
        }
    }
}

class AtomicInt64Class {
    var atom: AtomicInt64 = AtomicInt64(0)

    func load(): Int64 {
        return atom.load()
    }

    func fetchAdd(val: Int64): Int64 {
        return atom.fetchAdd(val)
    }

    func fetchSub(val: Int64): Int64 {
        return atom.fetchSub(val)
    }
}
