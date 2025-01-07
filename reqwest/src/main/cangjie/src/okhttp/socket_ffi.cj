/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2022-2024. All rights resvered.
 */
package ohos_app_cangjie_OkRequest.okhttp

let AI_IPPROTO_TCP: UInt8 = 6
let AI_IPPROTO_UDP: UInt8 = 17

let SOCK_ADDR_IPV4_LEN: Int64 = 4
let SOCK_ADDR_IPV6_LEN: Int64 = 16

public func resolveDomain(net: SocketNet, domain: String): ArrayList<(SocketAddressKind, Array<UInt8>)> {
    var protocol = match (net) {
        case TCP => AI_IPPROTO_TCP
        case UDP => AI_IPPROTO_UDP
        case _ => throw HttpException("parse net = ${net} fail ")
    }
    var domainName = unsafe { LibC.mallocCString(domain) }
    var ip = http_SOCKET_GetAddrInfo(protocol, domainName)
    unsafe { LibC.free(domainName) }
    if (ip.isNull()) {
        throw HttpException("parse domain = ${domain} fail ")
    }
    let size = Int64(unsafe { ip.read() })

    let arr = ArrayList<(SocketAddressKind, Array<UInt8>)>()
    var index = 1
    for (_ in 0..size) {
        let sz = Int64(unsafe { ip.read(index) })
        index++
        if (sz != SOCK_ADDR_IPV4_LEN && sz != SOCK_ADDR_IPV6_LEN) {
            unsafe { free(ip) }
            throw HttpException("parse domain = ${domain} fail ")
        }
        let ips = Array<UInt8>(sz, item: 0)
        for (i in 0..sz) {
            ips[i] = unsafe { ip.read(i + index) }
        }
        index += sz
        match {
            case sz == SOCK_ADDR_IPV4_LEN => arr.prepend((IPv4, ips))
            case sz == SOCK_ADDR_IPV6_LEN => arr.append((IPv6, ips))
            case _ => ()
        }
    }
    unsafe { free(ip) }
    return arr
}
