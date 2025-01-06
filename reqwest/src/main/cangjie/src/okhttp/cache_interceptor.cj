/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2022-2024. All rights resvered.
 */

/**
 * @file
 * The file declares the CallServerInterceptor class.
 */

package ohos_app_cangjie_reqwest.okhttp

/**
 * The class is CacheInterceptor inherited from Interceptor
 * @author luoyukai4
 * @since 0.35.3
 */
public class CacheInterceptor <: Interceptor {
    let cache: Option<Cache>

    public init(cache: Option<Cache>) {
        this.cache = cache
    }

    public func intercept(chain: Chain): Response {
        let cacheCandidate: ?Response = cache?.get(chain.getRequest()) ?? None
        let strategy: CacheStrategy = CacheStrategyFactory(chain.getRequest(), cacheCandidate).get()
        let networkRequest: Option<Request> = strategy.networkRequest
        let cacheResponse: Option<Response> = strategy.cacheResponse

        if (has(cache)) {
            cache.getOrThrow().trackResponse(strategy)
        }

        if (has(cacheCandidate) && !has(cacheResponse)) {
            Util.closeQuietly(cacheCandidate.getOrThrow().getBody())
        }

        if (!has(networkRequest) && !has(cacheResponse)) {
            return Response.builder().request(chain.getRequest()).protocol(Protocol.HTTP_1_1).code(504).message(
                "Unsatisfiable Request (only-if-cached)").body(ResponseBody("", 0, OkBuffer(ByteArrayStream()))).
                sentRequestAtMillis(-1).receivedResponseAtMillis(DateTime.now().toUnixTimeStamp().toMilliseconds()).
                build()
        }

        if (!has(networkRequest)) {
            return cacheResponse.getOrThrow().newBuilder().cacheResponse(stripBody(cacheResponse)).build()
        }

        let realNetworkRequest = networkRequest.getOrThrow()
        var networkResponse = Response.builder().build()

        try {
            networkResponse = chain.proceed(realNetworkRequest)
        } finally {
            if (!has(networkResponse) && has(cacheCandidate)) {
                Util.closeQuietly(cacheCandidate.getOrThrow().getBody())
            }
        }

        if (has(cacheResponse)) {
            let cacheRes = cacheResponse.getOrThrow()
            if (networkResponse.getCode() == HttpStatusCode.STATUS_NOT_MODIFIED) {
                let response: Response = cacheRes.newBuilder().header(
                    combine(cacheRes.getHeaders(), networkResponse.getHeaders())).sentRequestAtMillis(
                    networkResponse.getSentRequestAtMillis()).receivedResponseAtMillis(
                    networkResponse.getReceivedResponseAtMillis()).cacheResponse(stripBody(cacheResponse)).
                    networkResponse(stripBody(networkResponse)).build()
                networkResponse.getBody().getOrThrow().close()
                cache.getOrThrow().trackConditionalCacheHit()
                cache.getOrThrow().update(cacheRes, response)
                return response
            } else {
                Util.closeQuietly(cacheRes.getBody())
            }
        }

        let response: Response = networkResponse.newBuilder().cacheResponse(stripBody(cacheResponse)).networkResponse(
            stripBody(networkResponse)).build()

        if (has(cache)) {
            if (hasBody(response) && isCacheable(response, realNetworkRequest)) {
                let cacheRequest: Option<CacheRequest> = cache.getOrThrow().put(response)
                return cacheWritingResponse(cacheRequest, response)
            }

            if (invalidatesCache(realNetworkRequest.getMethod())) {
                try {
                    cache.getOrThrow().remove(realNetworkRequest)
                } catch (ignored: FSException | EOFException) {
                    // The cache cannot be written
                }
            }
        }

        return response
    }

    func cacheWritingResponse(cacheRequest: Option<CacheRequest>, response: Response) {
        let body: CacheRequest = match (cacheRequest) {
            case None => return response
            case Some(v) => v
        }

        let source = response.getBody().getOrThrow().getSource()
        let contentType = response.getHeader("Content-Type", "")
        let contentLength = response.getBody().getOrThrow().getContentLength()
        let responseBody = ResponseBody(contentType, contentLength, CacheWritingSource(source, body))
        return response.newBuilder().body(responseBody).build()
    }

    /** Combines cached headers with a network headers as defined by RFC 7234, 4.3.4. */
    private func combine(cachedHeaders: Header, networkHeaders: Header) {
        let result = Header()

        for ((k, v) in cachedHeaders) {
            let fieldName = k
            let value = v[0]
            if (equalsIgnoreCase("Warning", fieldName) && value.startsWith("1")) {
                continue
                // Drop 100-level freshness warnings.
            }

            let func1 = { => result.add(fieldName, value.trim())}
            if (isContentSpecificHeader(fieldName)) {
                func1()
            } else if (!isEndToEnd(fieldName)) {
                func1()
            } else if (has(networkHeaders.get(fieldName))) {
                func1()
            }
        }

        for ((k, v) in networkHeaders) {
            let func2 = { => result.add(k, v[0].trim())}
            if (isContentSpecificHeader(k)) {
                func2()
            } else if (!isEndToEnd(k)) {
                func2()
            }
        }

        return result
    }

    /* Returns true if {@code fieldName} is an end-to-end HTTP header, as defined by RFC 2616, 13.5.1.*/
    static func isEndToEnd(fieldName: String): Bool {
        return !equalsIgnoreCase("Connection", fieldName) && !equalsIgnoreCase("Keep-Alive", fieldName) &&
            !equalsIgnoreCase("Proxy-Authenticate", fieldName) && !equalsIgnoreCase("Proxy-Authorization", fieldName) &&
            !equalsIgnoreCase("TE", fieldName) && !equalsIgnoreCase("Trailers", fieldName) &&
            !equalsIgnoreCase("Transfer-Encoding", fieldName) && !equalsIgnoreCase("Upgrade", fieldName)
    }

    /* Returns true if fieldName is content specific and therefore should always be used */
    static func isContentSpecificHeader(fieldName: String): Bool {
        return equalsIgnoreCase("Content-Length", fieldName) || equalsIgnoreCase("Content-Encoding", fieldName) ||
            equalsIgnoreCase("Content-Type", fieldName)
    }

    private func stripBody(response: Option<Response>): Option<Response> {
        match (response) {
            case Some(v) => if (has(v.getBody())) {
                return v.newBuilder().body(Option<ResponseBody>.None).build()
            } else {
                return v
            }

            case None => return Option<Response>.None
        }
    }
}

class CacheStrategyFactory {
    let request: Request
    let cacheResponse: Option<Response>
    var servedDate: Option<DateTime> = Option<DateTime>.None
    var servedDateString: String = ""
    var lastModified: Option<DateTime> = Option<DateTime>.None
    var lastModifiedString: String = ""
    var expires: Option<DateTime> = Option<DateTime>.None
    var etag: String = ""
    var ageSeconds: Int64 = 0
    let nowMillis = DateTime.now().toUnixTimeStamp().toMilliseconds()
    var sentRequestMillis: Int64 = 0
    var receivedResponseMillis: Int64 = 0

    public init(request: Request, cacheResponse: Option<Response>) {
        this.request = request
        this.cacheResponse = cacheResponse

        if (has(cacheResponse)) {
            let cacheRes = cacheResponse.getOrThrow()
            this.sentRequestMillis = cacheRes.getSentRequestAtMillis()
            this.receivedResponseMillis = cacheRes.getReceivedResponseAtMillis()
            let headers: Header = cacheRes.getHeaders()
            for ((k, v) in headers) {
                let value = v[0]
                if (equalsIgnoreCase("Date", k)) {
                    servedDate = CookieUtil.parseExpires(value, 0, value.size)
                } else if (equalsIgnoreCase("Expires", k)) {
                    expires = CookieUtil.parseExpires(value, 0, value.size)
                } else if (equalsIgnoreCase("Last-Modified", k)) {
                    lastModified = CookieUtil.parseExpires(value, 0, value.size)
                    lastModifiedString = value
                } else if (equalsIgnoreCase("ETag", k)) {
                    etag = value
                } else if (equalsIgnoreCase("Age", k)) {
                    ageSeconds = Util.parseSeconds(value, -1)
                }
            }
        }
    }

    public func get(): CacheStrategy {
        let candidate: CacheStrategy = getCandidate()

        if (has(candidate.networkRequest)) {
            if (request.getCacheControl().onlyIfCached()) {
                return CacheStrategy(Option<Request>.None, Option<Response>.None)
            }
        }

        return candidate
    }

    private func hasConditions(request: Request): Bool {
        return request.getHeader("If-Modified-Since", "") != "" || request.getHeader("If-None-Match", "") != ""
    }

    private func getCandidate() {
        //没有从缓存目录解析到response, 直接使用网络请求
        if (!has(cacheResponse)) {
            return CacheStrategy(request, Option<Response>.None)
        }

        let cacheResp = cacheResponse.getOrThrow()

        //对缓存的response的状态码进行校验，一些特殊的状态码不论怎样都走网络请求
        if (!isCacheable(cacheResp, request)) {
            return CacheStrategy(request, Option<Response>.None)
        }

        let requestCaching: CacheControl = request.getCacheControl()

        // 如果请求的Cache-Control中指定了no-cache，则使用网络请求,或者请求头中配置缓存过期时间则使用网络请求
        if (requestCaching.noCache() || hasConditions(request)) {
            return CacheStrategy(request, Option<Response>.None)
        }

        let responseCaching: CacheControl = cacheResp.getCacheControl()

        // 计算当前缓存的response的存活时间以及缓存应当被刷新的时间
        let ageMillis = cacheResponseAge()
        var freshMillis = computeFreshnessLifetime()

        if (requestCaching.maxAgeSeconds() != -1) {
            freshMillis = min(freshMillis, requestCaching.maxAgeSeconds() * 1000)
        }

        var minFreshMillis = 0
        if (requestCaching.minFreshSeconds() != -1) {
            minFreshMillis = requestCaching.minFreshSeconds()
        }

        var maxStaleMillis = 0

        if (!responseCaching.mustRevalidate() && requestCaching.maxStaleSeconds() != -1) {
            maxStaleMillis = requestCaching.maxStaleSeconds() * 1000
        }

        // 对未超过时限的缓存，直接采用缓存数据策略
        if (!responseCaching.noCache() && ageMillis + minFreshMillis < freshMillis + maxStaleMillis) {
            let builder: ResponseBuilder = cacheResp.newBuilder()
            builder.addHeader("Warning", "110 HttpURLConnection \"Response is stale\"")
            var oneDayMillis = 24 * 60 * 60 * 1000
            let falg = isFreshnessLifetimeHeuristic()
            if (falg && ageMillis > oneDayMillis) {
                builder.addHeader("Warning", "113 HttpURLConnection \"Heuristic expiration\"")
            }

            return CacheStrategy(Option<Request>.None, builder.build())
        }

        //对If-None-Match、If-Modified-Since等Header进行处理
        var conditionName: String
        var conditionValue: String

        //优限度为etag>lastModified>servedDate
        if (etag != "") {
            conditionName = "If-None-Match"
            conditionValue = etag
        } else if (has(lastModified)) {
            conditionName = "If-Modified-Since"
            conditionValue = lastModifiedString
        } else if (has(servedDate)) {
            conditionName = "If-Modified-Since"
            conditionValue = servedDateString
        } else {
            //response未配置缓存过期时间则使用网络请求
            return CacheStrategy(request, Option<Response>.None)
        }

        //存在的话,则在请求中添加该请求头并合本地cacheResponse创建缓存策略
        let conditionalRequestHeaders = request.getHeaders().clone()
        conditionalRequestHeaders.add(conditionName, conditionValue.trim())
        var conditionalRequest = request.newBuilder().header(conditionalRequestHeaders).build()
        return CacheStrategy(conditionalRequest, cacheResponse)
    }

    private func isFreshnessLifetimeHeuristic(): Bool {
        return cacheResponse.getOrThrow().getCacheControl().maxAgeSeconds() == -1 && !has(expires)
    }

    private func computeFreshnessLifetime(): Int64 {
        let responseCaching: CacheControl = cacheResponse.getOrThrow().getCacheControl()

        if (responseCaching.maxAgeSeconds() != -1) {
            return responseCaching.maxAgeSeconds() * 1000
        } else if (has(expires)) {
            let servedMillis = match (servedDate) {
                case Some(v) => v.toUnixTimeStamp().toMilliseconds()
                case None => receivedResponseMillis
            }
            var delta = expires.getOrThrow().toUnixTimeStamp().toMilliseconds() - servedMillis

            if (delta < 0) {
                delta = 0
            }

            return delta
        } else if (has(lastModified) && cacheResponse.getOrThrow().getRequest().getUrl().rawQuery == None) {
            let servedMillis = match (servedDate) {
                case Some(v) => v.toUnixTimeStamp().toMilliseconds()
                case None => sentRequestMillis
            }
            var delta = servedMillis - lastModified.getOrThrow().toUnixTimeStamp().toMilliseconds()

            if (delta < 0) {
                delta = 0
            }

            return delta / 10
        }
        return 0
    }

    private func cacheResponseAge(): Int64 {
        let apparentReceivedAge = match (servedDate) {
            case Some(v) => max(0, receivedResponseMillis - v.toUnixTimeStamp().toMilliseconds())
            case None => 0
        }

        let receivedAge = if (ageSeconds != -1) {
            max(apparentReceivedAge, ageSeconds * 1000)
        } else {
            apparentReceivedAge
        }

        let responseDuration = receivedResponseMillis - sentRequestMillis
        let residentDuration = nowMillis - receivedResponseMillis

        return receivedAge + responseDuration + residentDuration
    }
}

func isCacheable(response: Response, request: Request) {
    match (response.getCode()) {
        //以下code除非备header禁止,否则会缓存
        case 200 | 203 | 204 | 300 | 301 | 308 | 404 | 405 | 410 | 414 | 501 => ()

        //以下code只有在特定header下能缓存
        // s-maxage is not checked because httpclient4cj is a private cache that should ignore s-maxage.
        case 302 | 307 =>
            let flag1 = response.getHeader("Expires", "") != ""
            let flag2 = response.getCacheControl().maxAgeSeconds() != -1
            let flag3 = response.getCacheControl().isPublic()
            let flag4 = response.getCacheControl().isPrivate()
            let flag = flag1 || flag2 || flag3 || flag4
            if (!flag) {
                return false
            }

        //其他所有code都不缓存
        case _ => return false
    }
    if (!response.getCacheControl().noStore()) {
        if (!request.getCacheControl().noStore()) {
            return true
        }
    }
    return false
}

class CacheStrategy {
    public let networkRequest: Option<Request>
    public let cacheResponse: Option<Response>

    init(networkRequest: Option<Request>, cacheResponse: Option<Response>) {
        this.networkRequest = networkRequest
        this.cacheResponse = cacheResponse
    }
}
