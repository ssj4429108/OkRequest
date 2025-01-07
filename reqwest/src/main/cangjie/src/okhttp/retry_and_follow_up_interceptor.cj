/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2022-2024. All rights resvered.
 */

/**
 * @file
 * The file declares the RetryAndFollowUpInterceptor class.
 */

package ohos_app_cangjie_OkRequest.okhttp

/**
 * The class is RetryAndFollowUpInterceptor inherited from Interceptor
 * @author guo_tingtingtekla,luoyukai4
 * @since 0.29.3
 */
public class RetryAndFollowUpInterceptor <: Interceptor {
    /* let member client type is HttpClient */
    private let client: HttpClient

    /**
     * The Function is init constructor
     *
     * @param client of HttpClient
     * @since 0.29.3
     */
    public init(client: HttpClient) {
        this.client = client
    }

    /*max redirect count*/
    private static let MAX_FOLLOW_UPS: Int64 = 20

    /**
     * The Function is intercept
     *
     * @param chain of Chain
     *
     * @return Type of Response
     * @since 0.29.3
     */
    public func intercept(chain: Chain): Response {
        var request: Request = chain.getRequest()
        var priorResponse: Option<Response> = Option<Response>.None
        let transmitter: Transmitter = chain.getTransmitter()
        var followUpCount: Int64 = 0
        while (true) {
            transmitter.prepareToConnect(request)

            if (transmitter.isCanceled()) {
                throw HttpException("Canceled")
            }

            var response: Response = Response.builder().build()
            var success: Bool = false
            try {
                response = chain.proceed(request, transmitter, Option<Exchange>.None)
                success = true
            } catch (e1: RouteException) {
                if (!recover(e1.getLastConnectException(), transmitter, false)) {
                    throw e1.getFirstConnectException()
                }
                continue
            } catch (e1: HttpException) {
                if (!recover(e1, transmitter, !(e1 is ConnectionShutdownException))) {
                    throw e1
                }
                continue
            } finally {
                if (!success) {
                    transmitter.exchangeDoneDueToException()
                }
            }

            match (priorResponse) {
                case Some(resp) => response = response.newBuilder().prevResponse(
                    Option<Response>.Some(resp.newBuilder().body(Option<ResponseBody>.None).build())).build()
                case _ => ()
            }
            let route: Option<Route> = match (response.exchange) {
                case Some(ex) => ex.getConnection().getRoute()
                case None => Option<Route>.None
            }

            let followUp = followUpRequest(response, route)

            let exchange: Option<Exchange> = response.exchange
            let followUpBody: Option<RequestBody> = match (followUp) {
                case Some(r) => r.getBody()
                case _ => return response
            }

            match (followUpBody) {
                case Some(_) => return response
                case None => ()
            }

            Util.closeQuietly(response.getBody())

            if (transmitter.hasExchange()) {
                exchange.getOrThrow().detachWithViolence()
            }
            followUpCount++

            if (followUpCount > MAX_FOLLOW_UPS) {
                throw ProtocolException("Too many follow-up requests: ${followUpCount}")
            }

            request = followUp.getOrThrow()
            priorResponse = Option<Response>.Some(response)
        }
        return Response.builder().build()
    }

    private func recover(e: HttpException, transmitter: Transmitter, requestSendStarted: Bool) {
        if (!client.getRetryOnConnectionFailure()) {
            return false
        }

        if (!isRecoverable(e, requestSendStarted)) {
            return false
        }

        if (!transmitter.canRetry()) {
            return false
        }

        return true
    }

    private func isRecoverable(e: HttpException, requestSendStarted: Bool): Bool {
        match (e) {
            case _: ProtocolException => return false
            case conn: ConnectException =>
                let contain = conn.contain
                if (contain is SocketTimeoutException) {
                    return !requestSendStarted
                } else {
                    return false
                }
            case _ => return true
        }
    }

    /*
     * The Function is followUpRequest
     *
     * @param response of Response
     *
     * @return Type of Option<Request>
     * @since 0.29.3
     */
    func followUpRequest(response: Response, route: Option<Route>): Option<Request> {
        let code: Int64 = response.code
        let method: String = response.getRequest().getMethod()
        match (code) {
            case 307 | 308 =>
                // 307,308 If this is not a GET or HEAD request, the browser disables automatic redirection
                if (method != "GET" && method != "HEAD") {
                    return Option<Request>.None
                }

                return redirectRequest(response)
            case 300 | 301 | 302 | 303 => return redirectRequest(response)
            case 401 => return client.getAuthenticator()(route, response)
            case 408 =>
                if (!client.getRetryOnConnectionFailure()) {
                    // The application layer has directed us not to retry the request.
                    return Option<Request>.None
                }

                match (response.getPrevResponse()) {
                    case Some(resp) => if (resp.getCode() == HttpStatusCode.STATUS_REQUEST_TIMEOUT) {
                        return Option<Request>.None
                    }
                    case _ => ()
                }

                if (retryAfter(response, 0) > 0) {
                    return Option<Request>.None
                }

                return response.getRequest()
            case 503 =>
                match (response.getPrevResponse()) {
                    case Some(resp) => if (resp.getCode() == HttpStatusCode.STATUS_SERVICE_UNAVAILABLE) {
                        return Option<Request>.None
                    }
                    case _ => ()
                }

                if (retryAfter(response, Int64.Max) == 0) {
                    return response.getRequest()
                }

                return Option<Request>.None
            case _ => return Option<Request>.None
        }
    }

    /*
     * The Function is redirectRequest
     *
     * @param response of Response
     *
     * @return Type of Option<Request>
     * @since 0.29.3
     */
    func redirectRequest(response: Response): Option<Request> {
        if (!client.getFollowRedirects()) {
            return Option<Request>.None
        }

        let location: String = response.getHeader("Location", "")

        if (location == "") {
            return Option<Request>.None
        }

        let url: URL = response.getRequest().getUrl().resolveURL(URL.parse(location))
        let method: String = response.getRequest().getMethod()

        if (url.scheme != response.getRequest().getUrl().scheme && !client.getFollowSslRedirects()) {
            return Option<Request>.None
        }

        let requestBuilder: RequestBuilder = response.getRequest().newBuilder()

        //redirects should also maintain the request body
        if (permitsRequestBody(method)) {
            if (redirectsToGet(method)) {
                requestBuilder.method("GET")
                requestBuilder.removeHeader("Transfer-Encoding")
                requestBuilder.removeHeader("Content-Length")
                requestBuilder.removeHeader("Content-Type")
            } else {
                requestBuilder.method(method, body: response.getRequest().getBody())
            }
        }

        // When redirecting across hosts, drop all authentication headers. This
        // is potentially annoying to the application layer since they have no
        // way to retain them.
        if (!Util.sameConnection(response.getRequest().getUrl(), url)) {
            requestBuilder.removeHeader("Authorization")
        }
        return Option<Request>.Some(requestBuilder.url(url).build())
    }

    /*
     * The Function is retryAfter
     *
     * @param userResponse of Response
     * @param defaultDelay of Int64
     *
     * @return Type of Int64
     * @since 0.29.3
     */
    func retryAfter(userResponse: Response, defaultDelay: Int64): Int64 {
        let header: String = userResponse.getHeader("Retry-After", "")

        if (header == "") {
            return defaultDelay
        }

        // currently ignores a HTTP-date, and assumes any non int 0 is a delay
        match (Int64.tryParse(header)) {
            case Some(delay) => return delay
            case None => return Int64.Max
        }
    }
}
