/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2022-2024. All rights resvered.
 */

/**
 * @file
 * The file declares the HttpClient class.
 */

package ohos_app_cangjie_reqwest.okhttp

/**
 * The class is HttpClient
 * @author guo_tingtingtekla,luoyukai4
 * @since 0.29.3
 */
public class HttpClient {
    /* var member dispatcher type is Dispatcher */
    var dispatcher: Dispatcher

    /* var member interceptors type is ArrayList<Interceptor> */
    var interceptors: ArrayList<Interceptor>

    /* var member networkInterceptors type is ArrayList<Interceptor> */
    var networkInterceptors: ArrayList<Interceptor>

    /* var member followRedirects type is Bool */
    var followRedirects: Bool

    /* var member retryOnConnectionFailure type is Bool */
    var retryOnConnectionFailure: Bool

    /* var member connectionPool type is Option<ConnectionPool> */
    var connectionPool: Option<ConnectionPool> = Option<ConnectionPool>.None

    /* var member cookieJar type is CookieJar */
    var cookieJar: CookieJar
    private var connectTimeout: Option<Duration>
    private var readTimeout: Option<Duration>
    private var writeTimeout: Option<Duration>

    private var protocols: ArrayList<String>
    private var tlsConfig: Option<TlsClientConfig>
    private var authenticator: (Option<Route>, Response) -> Option<Request>
    private var followSslRedirects: Bool
    private var eventListener: EventListener
    var cache: Option<Cache>

    /**
     * The Function is init constructor
     *
     * @param builder of HttpClientBuilder
     * @since 0.29.3
     */
    public init(builder: HttpClientBuilder) {
        this.dispatcher = builder.dispatcherBuild
        this.interceptors = builder.interceptorsBuild
        this.networkInterceptors = builder.networkInterceptorsBuild
        this.followRedirects = builder.followRedirectsBuild
        this.followSslRedirects = builder.followSslRedirectsBuild
        this.retryOnConnectionFailure = builder.retryOnConnectionFailureBuild
        this.connectionPool = builder.connectionPoolBuild
        this.cookieJar = builder.cookieJarBuild
        this.connectTimeout = builder.connectTimeoutBuild
        this.readTimeout = builder.readTimeoutBuild
        this.writeTimeout = builder.writeTimeoutBuild
        this.tlsConfig = builder.tlsConfigBuild
        this.protocols = builder.protocolsBuild
        this.authenticator = builder.authenticatorBuild
        this.eventListener = builder.listenerBuild
        this.cache = builder.cacheBuild
    }

    /**
     * The Function is builder
     *
     * @return Type of HttpClientBuilder
     * @since 0.29.3
     */
    public static func builder(): HttpClientBuilder {
        return HttpClientBuilder()
    }

    /**
     * The Function is newCall
     *
     * @param request of Request
     *
     * @return Type of Call
     * @since 0.29.3
     */
    public func newCall(request: Request): Call {
        return RealCall.newRealCall(this, request, false)
    }

    /**
     * The Function is getFollowRedirects
     *
     * @return Type of Bool
     * @since 0.29.3
     */
    public func getFollowRedirects(): Bool {
        return followRedirects
    }

    /**
     * The Function is getRetryOnConnectionFailure
     *
     * @since 0.29.3
     */
    public func getRetryOnConnectionFailure() {
        return retryOnConnectionFailure
    }

    /**
     * The Function is getConnectionPool
     *
     * @return Type of Option<ConnectionPool>
     * @since 0.29.3
     */
    public func getConnectionPool(): Option<ConnectionPool> {
        return connectionPool
    }

    /**
     * The Function is getDispatcher
     *
     * @return Type of Dispatcher
     * @since 0.29.3
     */
    public func getDispatcher(): Dispatcher {
        return dispatcher
    }

    /**
     * The Function is getInterceptors
     *
     * @return Type of ArrayList<Interceptor>
     * @since 0.29.3
     */
    public func getInterceptors(): ArrayList<Interceptor> {
        return interceptors
    }

    /**
     * The Function is getNetworkInterceptors
     *
     * @return Type of ArrayList<Interceptor>
     * @since 0.29.3
     */
    public func getNetworkInterceptors(): ArrayList<Interceptor> {
        return networkInterceptors
    }

    /**
     * The Function is getCookieJar
     *
     * @return Type of CookieJar
     * @since 0.29.3
     */
    public func getCookieJar(): CookieJar {
        return cookieJar
    }

    public func getConnectTimeout(): Option<Duration> {
        return connectTimeout
    }

    public func getReadTimeout(): Option<Duration> {
        return readTimeout
    }

    public func getWriteTimeout(): Option<Duration> {
        return writeTimeout
    }

    public func getProtocols(): ArrayList<String> {
        return protocols
    }

    public func getTlsConfig(): Option<TlsClientConfig> {
        return tlsConfig
    }

    public func getAuthenticator(): (Option<Route>, Response) -> Option<Request> {
        return authenticator
    }

    public func getFollowSslRedirects(): Bool {
        return followSslRedirects
    }

    public func getEventListener(): EventListener {
        return eventListener
    }

    public func getCache(): Option<Cache> {
        return cache
    }
}
