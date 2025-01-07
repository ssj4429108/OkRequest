/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2022-2024. All rights resvered.
 */

/**
 * @file
 * The file declares the Address class.
 */

package ohos_app_cangjie_OkRequest.okhttp

/**
 * The class is Address
 * @author guo_tingtingtekla,luoyukai4
 * @since 0.29.3
 */
public class Address <: Hashable & Equatable<Address> {
    /** var member url type is URL */
    public var url: URL
    private var tlsConfig: Option<TlsClientConfig>

    private var protocols: ArrayList<String>

    /**
     * The Function is init constructor
     *
     * @param url of URL
     * @since 0.29.3
     */
    public init(url: URL, protocols: ArrayList<String>, tlsConfig: Option<TlsClientConfig>) {
        this.url = url
        this.protocols = protocols
        this.tlsConfig = tlsConfig
    }

    public init(url: URL, protocols: ArrayList<String>) {
        this.url = url
        this.protocols = protocols
        this.tlsConfig = None
    }

    /**
     * The Function is getUrl
     *
     * @return Type of URL
     * @since 0.29.3
     */
    public func getUrl(): URL {
        return url
    }

    /**
     * The Function is getProtocols
     *
     * @return Type of ArrayList<String>
     * @since 0.30.4.
     */
    public func getProtocols(): ArrayList<String> {
        return protocols
    }

    /**
     * The Function is getTlsConfig
     *
     * @return Type of Option<TlsClientConfig> >
     * @since 0.30.4.
     */
    public func getTlsConfig(): Option<TlsClientConfig> {
        return tlsConfig
    }

    @OverflowWrapping
    public func hashCode(): Int64 {
        var result: Int64 = 17
        result = 31 * result + url.toString().hashCode()
        var listCode = 1
        for (i in 0..protocols.size) {
            listCode = 31 * listCode + protocols[i].toString().hashCode()
        }
        result = 31 * result + listCode
        return result
    }

    public operator func ==(rhs: Address): Bool {
        return url.toString().equals(rhs.getUrl().toString()) && equalsProtocols(rhs) && equalsTlsConfig(rhs)
    }

    public operator func !=(rhs: Address): Bool {
        return !(this == rhs)
    }

    func equalsProtocols(rhs: Address): Bool {
        let it1 = protocols.iterator()
        let it2 = rhs.getProtocols().iterator()

        while (true) {
            let next1 = match (it1.next()) {
                case Some(conn) => conn
                case None => ""
            }
            let next2 = match (it2.next()) {
                case Some(conn) => conn
                case None => ""
            }
            if (!next1.equals(next2)) {
                return false
            }
            if (next1 == "" || next2 == "") {
                break
            }
        }

        return true
    }

    func equalsTlsConfig(rhs: Address): Bool {
        let path1 = match (tlsConfig) {
            case Some(ts) => ts.domain ?? ""
            case None => ""
        }
        let path2 = match (rhs.getTlsConfig()) {
            case Some(ts) => ts.domain ?? ""
            case None => ""
        }
        return path1.equals(path2)
    }
}
