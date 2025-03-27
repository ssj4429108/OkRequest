/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2022-2024. All rights resvered.
 */

/**
 * @file
 * The file declares the CallServerInterceptor class.
 */

package ohos_app_cangjie_OkRequest.okhttp
import ohos.hilog.Hilog

/**
 * The class is CallServerInterceptor inherited from Interceptor
 * @author guo_tingtingtekla,luoyukai4
 * @since 0.29.3
 */
public class CallServerInterceptor <: Interceptor {
    /** let member forWebSocket type is Bool */
    public let forWebSocket: Bool

    /**
     * The Function is init constructor
     *
     * @param forWebSocket of Bool
     * @since 0.29.3
     */
    public init(forWebSocket: Bool) {
        this.forWebSocket = forWebSocket
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
        let exchange: Exchange = chain.getExchange()
        exchange.writeRequestHeaders(request)
        let sentRequestMillis = DateTime.now().toUnixTimeStamp().toMilliseconds()
        var responseBuilder: Option<ResponseBuilder> = None
        var responseHeadersStarted = false

        if (permitsRequestBody(request.getMethod()) && has(request.getBody())) {
            let body = request.getBody().getOrThrow()
            if ("100-continue" == request.getHeader("Expect", "").toLower()) {
                exchange.flushRequest()
                responseHeadersStarted = true
                exchange.responseHeadersStart()
                responseBuilder = exchange.readResponseHeaders(true)
            }
            match (responseBuilder) {
                case None =>
                    let bufferedRequestBody = exchange.createRequestBody(request)
                    body.writeTo(bufferedRequestBody)
                    bufferedRequestBody.close()
                case Some(_) =>
                    exchange.noRequestBody()
                    if (!exchange.getConnection().isMultiplexed()) {
                        exchange.noNewExchangesOnConnection()
                    }
            }
        } else {
            exchange.noRequestBody()
        }
        if (request.body.isNone()) {
            exchange.finishRequest()
        }

        Hilog.info(3, 'ok-request', "finish request")
        if (!responseHeadersStarted) {
            Hilog.info(3, 'ok-request', "header response start")
            exchange.responseHeadersStart()
            Hilog.info(3, 'ok-request', "header response end")
        }

        if (!has(responseBuilder)) {
            Hilog.info(3, 'ok-request', "read response header start")
            responseBuilder = exchange.readResponseHeaders(false)
            Hilog.info(3, 'ok-request', "read response header end")
        }

        Hilog.info(3, 'ok-request', "response start")
        let response: Response = responseBuilder.getOrThrow().request(request).build()
        return checkResponse(exchange, request, response, sentRequestMillis)
    }

    private func checkResponse(
        exchange: Exchange,
        request: Request,
        checkResponse: Response,
        sentRequestMillis: Int64
    ): Response {
        var response: Response = checkResponse
        let code = response.getCode()

        if (code == 100) {
            response = exchange.readResponseHeaders(false).getOrThrow().request(request).sentRequestAtMillis(
                sentRequestMillis).receivedResponseAtMillis(DateTime.now().toUnixTimeStamp().toMilliseconds()).build()
        }

        response = response.newBuilder().body(exchange.openResponseBody(response)).sentRequestAtMillis(
            sentRequestMillis).receivedResponseAtMillis(DateTime.now().toUnixTimeStamp().toMilliseconds()).build()

        exchange.responseHeadersEnd(response)

        if ("close".equals(response.getRequest().getHeader("Connection", "")) || "close".equals(
            response.getHeader("Connection", ""))) {
            exchange.noNewExchangesOnConnection()
        }

        if (code == 204 || code == 205) {
            match (response.getBody()) {
                case Some(body) => if (body.getContentLength() > 0) {
                    throw ProtocolException("HTTP ${code} had non-zero Content-Length: ${body.getContentLength()}")
                }
                case None => ()
            }
        }
        let body = response.body.getOrThrow()
        Hilog.info(3, 'ok-request', "response end: ${body.contentLength}")
        return response
    }
}
