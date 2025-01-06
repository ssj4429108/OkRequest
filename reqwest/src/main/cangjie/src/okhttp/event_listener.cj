/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2022-2024. All rights resvered.
 */

/**
 * @file
 * The file declares the NoneEventListener class.
 */

package ohos_app_cangjie_reqwest.okhttp

/*
 * The class is NoneEventListener inherited from EventListener
 * @author luoyukai4
 * @since 0.35.6
 */
class NoneEventListener <: EventListener {
    public func callStart(_: Call): Unit {}

    public func callEnd(_: Call): Unit {}

    public func dnsStart(_: Call, _: String): Unit {}

    public func dnsEnd(_: Call, _: String, _: ArrayList<Route>): Unit {}

    public func connectStart(_: Call, _: SocketAddress): Unit {}

    public func connectEnd(_: Call, _: SocketAddress, _: Protocol): Unit {}

    public func secureConnectStart(_: Call): Unit {}

    public func secureConnectEnd(_: Call, _: TlsClientConfig): Unit {}

    public func connectFailed(_: Call, _: SocketAddress, _: Protocol, _: HttpException): Unit {}

    public func requestHeadersStart(_: Call): Unit {}

    public func requestHeadersEnd(_: Call): Unit {}

    public func requestBodyStart(_: Call): Unit {}

    public func requestBodyEnd(_: Call, _: Int64): Unit {}

    public func requestFailed(_: Call, _: HttpException): Unit {}

    public func responseHeadersStart(_: Call): Unit {}

    public func responseHeadersEnd(_: Call, _: Response): Unit {}

    public func responseBodyStart(_: Call): Unit {}

    public func responseBodyEnd(_: Call, _: Int64): Unit {}

    public func responseFailed(_: Call, _: HttpException): Unit {}
}
