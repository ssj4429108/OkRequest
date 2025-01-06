/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2022-2024. All rights resvered.
 */

/**
 * @file
 * The file declares the Response class.
 */

package ohos_app_cangjie_reqwest.okhttp

/**
 * The class is Response
 * @author guo_tingtingtekla,luoyukai4
 * @since 0.29.3
 */
public class Response <: ToString {
    /* var member request type is Request */
    let request: Request

    /* var member protocol type is Protocol */
    let protocol: Protocol

    /* var member code type is Int64 */
    let code: Int64

    /* var member message type is String */
    let message: String

    /* var member header type is Header */
    let header: Header

    /* var member body type is Option<ResponseBody> */
    let body: Option<ResponseBody>

    /* var member prevResponse type is Option<Response> */
    let prevResponse: Option<Response>
    let cacheResponse: Option<Response>
    let networkResponse: Option<Response>
    private var cacheControl: Option<CacheControl> = Option<CacheControl>.None
    var exchange: Option<Exchange>
    let sentRequestAtMillis: Int64
    let receivedResponseAtMillis: Int64

    /**
     * The Function is init constructor
     *
     * @param builder of ResponseBuilder
     * @since 0.29.3
     */
    public init(builder: ResponseBuilder) {
        this.request = builder.requestBuild
        this.protocol = builder.protocolBuild
        this.code = builder.codeBuild
        this.message = builder.messageBuild
        this.header = builder.headerBuild
        this.body = builder.bodyBuild
        this.prevResponse = builder.prevResponseBuild
        this.exchange = builder.exchange
        this.sentRequestAtMillis = builder.sentRequestAtMillisBuild
        this.receivedResponseAtMillis = builder.receivedResponseAtMillisBuild
        this.networkResponse = builder.networkResponseBuild
        this.cacheResponse = builder.cacheResponseBuild
    }

    /**
     * The Function is getRequest
     *
     * @return Type of Request
     * @since 0.29.3
     */
    public func getRequest(): Request {
        return request
    }

    /**
     * Returns the HTTP protocol, such as {@link Protocol#HTTP_1_1} or {@link Protocol#HTTP_1_0}.
     */
    public func getProtocol(): Protocol {
        return protocol
    }

    /** Returns the HTTP status code. */
    public func getCode(): Int64 {
        return code
    }

    /**
     * Returns true if the code is in [200..300), which means the request was successfully received,
     * understood, and accepted.
     */
    public func isSuccess(): Bool {
        return code >= 200 && code < 300
    }

    /** Returns the HTTP status message. */
    public func getMessage(): String {
        return message
    }

    /**
     * The Function is getHeaders
     *
     * @return Type of Header
     * @since 0.29.3
     */
    public func getHeaders(): Header {
        return header
    }

    /**
     * The Function is getHeader
     *
     * @param name of String
     *
     * @return Type of String
     * @since 0.29.3
     */
    public func getHeader(name: String): Option<String> {
        return header.getString(name)
    }

    /**
     * The Function is getHeader
     *
     * @param name of String
     * @param defaultValue of String
     *
     * @return Type of String
     * @since 0.29.3
     */
    public func getHeader(name: String, defaultValue: String): String {
        return header.getString(name) ?? defaultValue
    }

    /**
     * The Function is getBody
     *
     * @return Type of Option<ResponseBody>
     * @since 0.29.3
     */
    public func getBody(): Option<ResponseBody> {
        return this.body
    }

    /**
     * The Function is getPrevResponse
     *
     * @return Type of Option<Response>
     * @since 0.29.3
     */
    public func getPrevResponse(): Option<Response> {
        return prevResponse
    }

    /** Returns true if this response redirects to another resource. */
    public func isRedirect(): Bool {
        if (code == StatusLine.HTTP_PERM_REDIRECT || code == StatusLine.HTTP_TEMP_REDIRECT || code == StatusLine.
            HTTP_MULT_CHOICE || code == StatusLine.HTTP_MOVED_PERM || code == StatusLine.HTTP_MOVED_TEMP || code ==
            StatusLine.HTTP_SEE_OTHER) {
            return true
        } else {
            return false
        }
    }

    /**
     * Closes the response body. Equivalent to {@code body().close()}.
     *
     * <p>It is an error to close a response that is not eligible for a body. This includes the
     * responses returned from {@link #cacheResponse}, {@link #networkResponse}, and {@link
     * #priorResponse()}.
     */
    public func close() {
        match (body) {
            case Some(v) => v.close()
            case None => throw IllegalStateException("response is not eligible for a body and must not be closed")
        }
    }

    /**
     * The Function is toString
     *
     * @return Type of String
     * @since 0.29.3
     */
    public func toString(): String {
        return "Response{protocol=${protocol}, code=${code}, message=${message}, url=${request.getUrl()}}"
    }

    /**
     * The Function is builder
     *
     * @return Type of ResponseBuilder
     * @since 0.29.3
     */
    public static func builder(): ResponseBuilder {
        return ResponseBuilder()
    }

    func initExchange(deferredTrailers: Exchange) {
        this.exchange = deferredTrailers
    }

    /**
     * The Function is newBuilder
     *
     * @return Type of ResponseBuilder
     * @since 0.29.3
     */
    public func newBuilder(): ResponseBuilder {
        return ResponseBuilder(this)
    }

    /**
     * Returns the cache control directives for this response. This is never null, even if this
     * response contains no {@code Cache-Control} header.
     *
     * @since 0.30.4
     */
    public func getCacheControl(): CacheControl {
        match (cacheControl) {
            case Some(b) => return b
            case None =>
                let cacheControl = CacheControl.parse(header)
                this.cacheControl = cacheControl
                return cacheControl
        }
    }

    public func getSentRequestAtMillis(): Int64 {
        return sentRequestAtMillis
    }

    public func getReceivedResponseAtMillis(): Int64 {
        return receivedResponseAtMillis
    }

    public func getNetworkResponse(): Option<Response> {
        return networkResponse
    }

    public func getCacheResponse(): Option<Response> {
        return cacheResponse
    }


}
