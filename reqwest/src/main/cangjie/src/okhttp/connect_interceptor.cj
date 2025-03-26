/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2022-2024. All rights resvered.
 */

/**
 * @file
 * The file declares the ConnectInterceptor class.
 */

package ohos_app_cangjie_OkRequest.okhttp
import ohos.hilog.Hilog

/**
 * The class is ConnectInterceptor inherited from Interceptor
 * @author guo_tingtingtekla,luoyukai4
 * @since 0.29.3
 */
public class ConnectInterceptor <: Interceptor {
    /** let member client type is HttpClient */
    public let client: HttpClient

    /**
     * The Function is init constructor
     *
     * @param client of HttpClient
     * @since 0.29.3
     */
    public init(client: HttpClient) {
        this.client = client
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
        let transmitter: Transmitter = chain.getTransmitter()
        let request: Request = chain.getRequest()
        let doExtensiveHealthChecks: Bool = !request.getMethod().equals(METHOD_GET)
        return chain.proceed(request, chain.getTransmitter(), transmitter.newExchange(chain, doExtensiveHealthChecks))
    }
}
