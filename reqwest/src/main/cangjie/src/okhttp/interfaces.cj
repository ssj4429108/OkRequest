/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2022-2024. All rights resvered.
 */

/**
 * @file
 * The file declars the all interfaces.
 */

package ohos_app_cangjie_reqwest.okhttp

/**
 * The interface is ExchangeCodec
 * @author luoyukai4
 * @since 0.29.3
 */
public interface ExchangeCodec {
    func readResponseHeaders(expectContinue: Bool): Option<ResponseBuilder>

    func reportedContentLength(response: Response): Int64

    func openResponseBodySource(response: Response): Source

    func getConnection(): Connection

    func cancel(): Unit

    func createRequestBody(request: Request): Sink

    func writeRequestHeaders(request: Request): Unit

    func flushRequest(): Unit

    func getTrailers(): Header

    func finishRequest(): Unit
}

public interface Sink {
    func write(bytes: Array<Byte>): Unit
    func flush(): Unit
    func close(): Unit
}

public interface Source <: Resource {
    func read(bytes: ByteArrayStream, byteCount: Int64): Int64
    func close(): Unit
    func isClosed(): Bool
}

/**
 * The interface is Interceptor
 * @author guo_tingtingtekla,luoyukai4
 * @since 0.29.3
 */
public interface Interceptor {
    /*
     * The Function is intercept
     *
     * @param chain of Chain
     *
     * @return Type of Response
     * @since 0.29.3
     */
    func intercept(chain: Chain): Response
}

/**
 * The interface is Callback
 * @author guo_tingtingtekla,luoyukai4
 * @since 0.29.3
 */
public interface Callback {
    /*
     * The Function is onFailure
     *
     * @param call of Call
     * @param e of Exception
     *
     * @return Type of Unit
     * @since 0.29.3
     */
    func onFailure(call: Call, e: Exception): Unit

    /*
     * The Function is onResponse
     *
     * @param call of Call
     * @param response of Response
     *
     * @return Type of Unit
     * @since 0.29.3
     */
    func onResponse(call: Call, response: Response): Unit
}

/**
 * The interface is Builder<T>
 * @author guo_tingtingtekla,luoyukai4
 * @since 0.29.3
 */
public interface Builder<T> {
    func build(): T
}

/**
 * The interface is Call
 * @author guo_tingtingtekla,luoyukai4
 * @since 0.29.3
 */
public interface Call {
    /*
     * The Function is getRequest
     *
     * @return Type of Request
     * @since 0.29.3
     */
    func getRequest(): Request

    /*
     * The Function is execute
     *
     * @return Type of Response
     * @since 0.29.3
     */
    func execute(): Response

    /*
     * The Function is enqueue
     *
     * @param responseCallback of Callback
     *
     * @return Type of Unit
     * @since 0.29.3
     */
    func enqueue(responseCallback: Callback): Unit

    /*
     * The Function is cancel
     *
     * @return Type of Unit
     * @since 0.29.3
     */
    func cancel(): Unit

    /*
     * The Function is isExecuted
     *
     * @return Type of Bool
     * @since 0.29.3
     */
    func isExecuted(): Bool

    /*
     * The Function is isCanceled
     *
     * @return Type of Bool
     * @since 0.29.3
     */
    func isCanceled(): Bool

    /*
     * The Function is clone
     *
     * @return Type of Call
     * @since 0.29.3
     */
    func clone(): Call
}

public interface CookieJar {
    func saveFromResponse(url: URL, cookies: Array<Cookie>): Unit

    func loadForRequest(url: URL): Array<Cookie>
}

public interface RequestBody {
    func contentType(): Option<MediaType>

    func getContentLength(): Int64

    func writeTo(sink: Sink): Unit

    func get(): InputStream
}

public interface EventListener {
    func callStart(call: Call): Unit

    func callEnd(call: Call): Unit

    func dnsStart(call: Call, domainName: String): Unit

    func dnsEnd(call: Call, domainName: String, allRoutes: ArrayList<Route>): Unit

    func connectStart(call: Call, socketAddress: SocketAddress): Unit

    func connectEnd(call: Call, socketAddress: SocketAddress, protocol: Protocol): Unit

    func secureConnectStart(call: Call): Unit

    func secureConnectEnd(call: Call, tlsConfig: TlsClientConfig): Unit

    func connectFailed(call: Call, socketAddress: SocketAddress, protocol: Protocol, e: HttpException): Unit

    func requestHeadersStart(call: Call): Unit

    func requestHeadersEnd(call: Call): Unit

    func requestBodyStart(call: Call): Unit

    func requestBodyEnd(call: Call, byteCount: Int64): Unit

    func requestFailed(call: Call, e: HttpException): Unit

    func responseHeadersStart(call: Call): Unit

    func responseHeadersEnd(call: Call, response: Response): Unit

    func responseBodyStart(call: Call): Unit

    func responseBodyEnd(call: Call, byteCount: Int64): Unit

    func responseFailed(call: Call, e: HttpException): Unit
}
