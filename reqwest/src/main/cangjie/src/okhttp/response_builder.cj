/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2022-2024. All rights resvered.
 */

/**
 * @file
 * The file declares the ResponseBuilder class.
 */

package ohos_app_cangjie_OkRequest.okhttp

/**
 * The class is ResponseBuilder inherited from Builder<Response>
 * @author guo_tingtingtekla,luoyukai4
 * @since 0.29.3
 */
public open class ResponseBuilder <: Builder<Response> {
    /* var member requestBuild type is Request */
    var requestBuild: Request = Request.builder().build()

    /* var member protocolBuild type is Protocol */
    var protocolBuild: Protocol = HTTP_1_1

    /* var member codeBuild type is Int64 */
    var codeBuild: Int64 = -1

    /* var member messageBuild type is String */
    var messageBuild: String = ""

    /* var member headerBuild type is Header */
    var headerBuild: Header = Header()

    /* var member bodyBuild type is Option<ResponseBody> */
    var bodyBuild: Option<ResponseBody> = Option<ResponseBody>.None

    /* var member prevResponseBuild type is Option<Response> */
    var prevResponseBuild: Option<Response> = Option<Response>.None
    var exchange: Option<Exchange> = None
    var sentRequestAtMillisBuild = 0
    var receivedResponseAtMillisBuild = 0
    var networkResponseBuild: Option<Response> = Option<Response>.None
    var cacheResponseBuild: Option<Response> = Option<Response>.None

    /**
     * The Function is init constructor
     *
     * @since 0.29.3
     */
    init() {}

    /**
     * The Function is init constructor
     *
     * @param response of Response
     * @since 0.29.3
     */
    init(response: Response) {
        this.requestBuild = response.getRequest()
        this.protocolBuild = response.getProtocol()
        this.codeBuild = response.getCode()
        this.messageBuild = response.getMessage()
        this.headerBuild = response.getHeaders().clone()
        this.bodyBuild = response.getBody()
        this.exchange = response.exchange
        this.networkResponseBuild = response.networkResponse
        this.cacheResponseBuild = response.cacheResponse
        this.prevResponseBuild = response.prevResponse
        this.sentRequestAtMillisBuild = response.sentRequestAtMillis
        this.receivedResponseAtMillisBuild = response.receivedResponseAtMillis
    }

    /**
     * The Function is request
     *
     * @param request of Request
     *
     * @return Type of ResponseBuilder
     * @since 0.29.3
     */
    public func request(request: Request): ResponseBuilder {
        this.requestBuild = request
        return this
    }

    /**
     * The Function is protocol
     *
     * @param protocol of Protocol
     *
     * @return Type of ResponseBuilder
     * @since 0.29.3
     */
    public func protocol(protocol: Protocol): ResponseBuilder {
        this.protocolBuild = protocol
        return this
    }

    /**
     * The Function is code
     *
     * @param code of Int64
     *
     * @return Type of ResponseBuilder
     * @since 0.29.3
     */
    public func code(code: Int64): ResponseBuilder {
        this.codeBuild = code
        return this
    }

    /**
     * The Function is message
     *
     * @param message of String
     *
     * @return Type of ResponseBuilder
     * @since 0.29.3
     */
    public func message(message: String): ResponseBuilder {
        this.messageBuild = message
        return this
    }

    /**
     * Sets the header named {@code name} to {@code value}. If this request already has any header
     * with that name, they are all replaced.
     */
    public func header(name: String, value: Array<String>): ResponseBuilder {
        headerBuild.set(name, ArrayList(value))
        return this
    }

    /**
     * The Function is addHeader
     *
     * @param name of String
     * @param value of String
     *
     * @return Type of ResponseBuilder
     * @since 0.29.3
     */
    public func addHeader(name: String, value: String): ResponseBuilder {
        headerBuild.add(name, value)
        return this
    }

    /**
     * The Function is removeHeader
     *
     * @param name of String
     *
     * @return Type of ResponseBuilder
     * @since 0.29.3
     */
    public func removeHeader(name: String): ResponseBuilder {
        headerBuild.remove(name)
        return this
    }

    /**
     * The Function is prevResponse
     *
     * @param prevResponse of Option<Response>
     *
     * @return Type of ResponseBuilder
     * @since 0.29.3
     */
    public func prevResponse(prevResponse: Option<Response>): ResponseBuilder {
        match (prevResponse) {
            case Some(resp) => checkPrevResponse(resp)
            case None => ()
        }
        this.prevResponseBuild = prevResponse
        return this
    }

    private func checkPrevResponse(response: Response): Unit {
        match (response.getBody()) {
            case Some(_) => throw IllegalArgumentException("prevResponse.body != None")
            case None => ()
        }
    }

    /**
     * The Function is body
     *
     * @param body of ResponseBody
     *
     * @return Type of ResponseBuilder
     * @since 0.29.3
     */
    public func body(body: Option<ResponseBody>): ResponseBuilder {
        this.bodyBuild = body
        return this
    }

    /**
     * The Function is header
     *
     * @param header of Header
     * @since 0.29.3
     */
    public func header(header: Header): ResponseBuilder {
        this.headerBuild = header
        return this
    }

    /**
     * The Function is build
     *
     * @return Type of Response
     * @since 0.29.3
     */
    public func build(): Response {
        return Response(this)
    }

    func initExchange(deferredTrailers: Exchange): Unit {
        this.exchange = Option<Exchange>.Some(deferredTrailers)
    }

    public func sentRequestAtMillis(sentRequestAtMillis: Int64): ResponseBuilder {
        this.sentRequestAtMillisBuild = sentRequestAtMillis
        return this
    }

    public func receivedResponseAtMillis(receivedResponseAtMillis: Int64): ResponseBuilder {
        this.receivedResponseAtMillisBuild = receivedResponseAtMillis
        return this
    }

    public func cacheResponse(cacheResponse: Option<Response>): ResponseBuilder {
        match (cacheResponse) {
            case Some(cacheResp) => checkSupportResponse("cacheResponse", cacheResp)
            case None => ()
        }
        this.cacheResponseBuild = cacheResponse
        return this
    }

    public func networkResponse(networkResponse: Option<Response>): ResponseBuilder {
        match (networkResponse) {
            case Some(networkResp) => checkSupportResponse("networkResponse", networkResp)
            case None => ()
        }
        this.networkResponseBuild = networkResponse
        return this
    }

    private func checkSupportResponse(name: String, response: Response) {
        if (has(response.getBody())) {
            throw IllegalArgumentException(name + ".body != None")
        } else if (has(response.getNetworkResponse())) {
            throw IllegalArgumentException(name + ".networkResponse != None")
        } else if (has(response.getCacheResponse())) {
            throw IllegalArgumentException(name + ".cacheResponse != None")
        } else if (has(response.getPrevResponse())) {
            throw IllegalArgumentException(name + ".prevResponse != None")
        }
    }
}
