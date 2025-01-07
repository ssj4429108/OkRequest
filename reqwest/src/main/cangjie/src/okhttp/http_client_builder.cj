/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2022-2024. All rights resvered.
 */

/**
 * @file
 * The file declares the HttpClientBuilder class.
 */

package ohos_app_cangjie_OkRequest.okhttp

/**
 * The class is HttpClientBuilder inherited from Builder<HttpClient>
 * @author guo_tingtingtekla,luoyukai4
 * @since 0.29.3
 */
public class HttpClientBuilder <: Builder<HttpClient> {
    /* var member dispatcherBuild type is Dispatcher */
    var dispatcherBuild: Dispatcher = Dispatcher()

    /* var member interceptorsBuild type is ArrayList<Interceptor> */
    var interceptorsBuild: ArrayList<Interceptor> = ArrayList<Interceptor>()

    /* var member networkInterceptorsBuild type is ArrayList<Interceptor> */
    var networkInterceptorsBuild: ArrayList<Interceptor> = ArrayList<Interceptor>()

    /* var member followRedirectsBuild type is Bool */
    var followRedirectsBuild: Bool = true

    /* var member retryOnConnectionFailureBuild type is Bool */
    var retryOnConnectionFailureBuild: Bool = true

    /* var member connectionPoolBuild type is Option<ConnectionPool> */
    var connectionPoolBuild: Option<ConnectionPool> = Option<ConnectionPool>.None

    /* var member cookieJarBuild type is CookieJar */
    var cookieJarBuild: CookieJar = NoCookieJar()
    var connectTimeoutBuild: Option<Duration> = Option<Duration>.Some(Duration.millisecond * 10000)
    var readTimeoutBuild: Option<Duration> = Option<Duration>.Some(Duration.millisecond * 10000)
    var writeTimeoutBuild: Option<Duration> = Option<Duration>.Some(Duration.millisecond * 10000)
    var tlsConfigBuild: Option<TlsClientConfig> = None
    var protocolsBuild: ArrayList<String> = ArrayList<String>([Protocol.get("HTTP/1.1").toString()])
    var followSslRedirectsBuild: Bool = true
    var authenticatorBuild: (Option<Route>, Response) -> Option<Request> = {
        _, _ => None
    }
    var listenerBuild: EventListener = NoneEventListener()
    var cacheBuild: Option<Cache> = Option<Cache>.None

    /**
     * The Function is build
     *
     * @return Type of HttpClient
     * @since 0.29.3
     */
    public func build(): HttpClient {
        return HttpClient(this)
    }

    init() {
        var cfg = TlsClientConfig()
        cfg.verifyMode = CertificateVerifyMode.TrustAll
        tlsConfigBuild = cfg
    }

    /**
     * The Function is dispatcher
     *
     * @param dispatcher of Dispatcher
     *
     * @return Type of HttpClientBuilder
     * @since 0.29.3
     */
    public func dispatcher(dispatcher: Dispatcher): HttpClientBuilder {
        this.dispatcherBuild = dispatcher
        return this
    }

    /**
     * The Function is followRedirects
     *
     * @param followRedirects of Bool
     *
     * @return Type of HttpClientBuilder
     * @since 0.29.3
     */
    public func followRedirects(followRedirects: Bool): HttpClientBuilder {
        this.followRedirectsBuild = followRedirects
        return this
    }

    /**
     * The Function is retryOnConnectionFailure
     *
     * @param retryOnConnectionFailure of Bool
     *
     * @return Type of HttpClientBuilder
     * @since 0.29.3
     */
    public func retryOnConnectionFailure(retryOnConnectionFailure: Bool): HttpClientBuilder {
        this.retryOnConnectionFailureBuild = retryOnConnectionFailure
        return this
    }

    /**
     * The Function is connectionPool
     *
     * @param connectionPool of Option<ConnectionPool>
     *
     * @return Type of HttpClientBuilder
     * @since 0.29.3
     */
    public func connectionPool(connectionPool: Option<ConnectionPool>): HttpClientBuilder {
        this.connectionPoolBuild = connectionPool
        return this
    }

    /**
     * The Function is addInterceptor
     *
     * @param interceptor of Interceptor
     *
     * @return Type of HttpClientBuilder
     * @since 0.29.3
     */
    public func addInterceptor(interceptor: Interceptor): HttpClientBuilder {
        this.interceptorsBuild.append(interceptor)
        return this
    }

    /**
     * The Function is addNetworkInterceptor
     *
     * @param interceptor of Interceptor
     *
     * @return Type of HttpClientBuilder
     * @since 0.29.3
     */
    public func addNetworkInterceptor(interceptor: Interceptor): HttpClientBuilder {
        this.networkInterceptorsBuild.append(interceptor)
        return this
    }

    /**
     * The Function is cookieJar
     *
     * @param cookieJar of CookieJar
     *
     * @return Type of HttpClientBuilder
     * @since 0.29.3
     */
    public func cookieJar(cookieJar: CookieJar): HttpClientBuilder {
        this.cookieJarBuild = cookieJar
        return this
    }

    /**
     * The Function is connectTimeout
     *
     * @param connectTimeout of Duration
     *
     * @return Type of HttpClientBuilder
     * @since 0.30.4
     */
    public func connectTimeout(connectTimeout: Duration): HttpClientBuilder {
        this.connectTimeoutBuild = Option<Duration>.Some(connectTimeout)
        return this
    }

    /**
     * The Function is readTimeout
     *
     * @param readTimeout of Duration
     *
     * @return Type of HttpClientBuilder
     * @since 0.30.4
     */
    public func readTimeout(readTimeout: Duration): HttpClientBuilder {
        this.readTimeoutBuild = Option<Duration>.Some(readTimeout)
        return this
    }

    /**
     * The Function is writeTimeout
     *
     * @param writeTimeout of Duration
     *
     * @return Type of HttpClientBuilder
     * @since 0.30.4
     */
    public func writeTimeout(writeTimeout: Duration): HttpClientBuilder {
        this.writeTimeoutBuild = Option<Duration>.Some(writeTimeout)
        return this
    }

    /*
     * set TlsClientConfig
     */
    public func tlsConfig(cfg: TlsClientConfig): HttpClientBuilder {
        this.tlsConfigBuild = cfg
        return this
    }

    public func protocols(protocols: ArrayList<String>): HttpClientBuilder {
        if (!protocols.contains(Protocol.get("H2_PRIOR_KNOWLEDGE").toString()) &&
            !protocols.contains(Protocol.get("HTTP/1.1").toString())) {
            throw IllegalArgumentException("protocols must contain h2_prior_knowledge or http/1.1")
        }
        if (protocols.contains(Protocol.get("H2_PRIOR_KNOWLEDGE").toString()) && protocols.size > 1) {
            throw IllegalArgumentException("protocols containing h2_prior_knowledge cannot use other protocols")
        }
        if (protocols.contains(Protocol.get("HTTP/1.0").toString())) {
            throw IllegalArgumentException("protocols must not contain http/1.0")
        }
        if (protocols.size == 0) {
            throw IllegalArgumentException("protocols must not contain empty")
        }
        this.protocolsBuild = protocols
        return this
    }

    public func authenticator(authenticator: (Option<Route>, Response) -> Option<Request>): HttpClientBuilder {
        this.authenticatorBuild = authenticator
        return this
    }

    public func followSslRedirects(followSslRedirects: Bool): HttpClientBuilder {
        this.followSslRedirectsBuild = followSslRedirects
        return this
    }

    public func eventListener(listener: EventListener): HttpClientBuilder {
        this.listenerBuild = listener
        return this
    }

    public func cache(cache: Option<Cache>): HttpClientBuilder {
        this.cacheBuild = cache
        return this
    }
}
