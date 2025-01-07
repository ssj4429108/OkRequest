/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2022-2024. All rights resvered.
 */

/**
 * @file
 * The file declares the BridgeInterceptor class.
 */

package ohos_app_cangjie_OkRequest.okhttp

/**
 * The class is BridgeInterceptor inherited from Interceptor
 * @author guo_tingtingtekla,luoyukai4
 * @since 0.29.3
 */
public class BridgeInterceptor <: Interceptor {
    /* let member cookieJar type is CookieJar */
    private let cookieJar: CookieJar

    /**
     * The Function is init constructor
     *
     * @param cookieJar of CookieJar
     * @since 0.29.3
     */
    public init(cookieJar: CookieJar) {
        this.cookieJar = cookieJar
    }

    /**
     * The Function is intercept
     *
     * @param chain of Chain
     *
     * @return Type of Response
     * @since 0.29.3
     */
    public func intercept(chain: Chain): Response {
        let request: Request = chain.getRequest()
        let requestBuilder: RequestBuilder = request.newBuilder()
        match (request.getBody()) {
            case Some(b) =>
                if (has(b.contentType())) {
                    requestBuilder.header("Content-Type", "${b.contentType().getOrThrow()}")
                }

                if (b.getContentLength() != -1) {
                    requestBuilder.header("Content-Length", "${b.getContentLength()}")
                    requestBuilder.removeHeader("Transfer-Encoding")
                } else {
                    requestBuilder.header("Transfer-Encoding", "chunked")
                    requestBuilder.removeHeader("Content-Length")
                }
                ()

            case _ => ()
        }
        if (request.getHeader("Host", "") == "") {
            requestBuilder.header("Host", request.getUrl().hostName)
        }
        if (request.getHeader("Connection", "") == "") {
            requestBuilder.header("Connection", "Keep-Alive")
        }

        var transparentGzip: Bool = false

        // If we add an "Accept-Encoding: gzip" header field we're responsible for also decompressing
        // the transfer stream.
        if (request.getHeader("Accept-Encoding", "") == "" && request.getHeader("Range", "") == "") {
            transparentGzip = true
            requestBuilder.header("Accept-Encoding", "gzip")
        }

        let cookies = cookieJar.loadForRequest(request.getUrl())

        if (cookies.size != 0) {
            requestBuilder.header("Cookie", cookieHeader(cookies))
        }

        if (request.getHeader("User-Agent", "") == "") {
            requestBuilder.header("User-Agent", "httpclient4cj")
        }

        var response: Response = chain.proceed(requestBuilder.build())
        let responseHeader: Header = response.getHeaders()
        receiveHeaders(cookieJar, request.getUrl(), responseHeader)
        let responseBuilder: ResponseBuilder = response.newBuilder().request(request)

        if (transparentGzip && "gzip".equals(response.getHeader("Content-Encoding", "")) && hasBody(response)) {
            let strippedHeader = response.getHeaders().clone()
            strippedHeader.remove("Content-Encoding")
            strippedHeader.remove("Content-Length")
            responseBuilder.header(strippedHeader)
            let contentType = response.getHeader("Content-Type", "")
            responseBuilder.body(
                ResponseBody(contentType, -1, OkGzipSource(response.getBody().getOrThrow().getSource()))
            )
        }

        return responseBuilder.build()
    }

    /*
     * The Function is cookieHeader
     *
     * @param cookies of Array<Cookie>
     *
     * @return Type of String
     * @since 0.29.3
     */
    func cookieHeader(cookies: Array<Cookie>): String {
        let sb: StringBuilder = StringBuilder()
        for (cookie in cookies) {
            sb.append("; ${cookie.name}=${cookie.value}")
        }
        return sb.toString()[2..]
    }
}

/**
 * The Function is hasBody
 *
 * @param response of Response
 *
 * @return Type of Bool
 * @since 0.29.3
 */
func hasBody(response: Response): Bool {
    if (response.getRequest().getMethod().equals("HEAD")) {
        return false
    }

    let responseCode: Int64 = response.getCode()

    if ((responseCode < HttpStatusCode.STATUS_CONTINUE || responseCode >= HttpStatusCode.STATUS_OK) && responseCode !=
        HttpStatusCode.STATUS_NO_CONTENT && responseCode != HttpStatusCode.STATUS_NOT_MODIFIED) {
        return true
    }

    let contentLength = response.getHeader("Content-Length", "")

    if (contentLength != "" && ((Int64.tryParse(contentLength) ?? -1) != -1) || "chunked".equals(
        response.getHeader("Transfer-Encoding", ""))) {
        return true
    }
    return false
}

func contentLength(response: Response): Int64 {
    return contentLength(response.getHeaders())
}

func contentLength(headers: Header): Int64 {
    return Int64.tryParse(headers.getString("Content-Length") ?? "") ?? -1
}
