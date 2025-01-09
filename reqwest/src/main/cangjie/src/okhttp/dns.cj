/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2022-2024. All rights resvered.
 */
package ohos_app_cangjie_OkRequest.okhttp

@When[os != "Windows"]
@C
struct addrinfo {
    var ai_flags: Int32 = 0
    var ai_family: Int32 = 0
    var ai_socktype: Int32 = 0
    var ai_protocol: Int32 = 0
    var ai_addrlen: Int32 = 0
    var ai_addr: CPointer<sockaddr_in> = CPointer<sockaddr_in>()
    var ai_canonname: CPointer<UInt8> = CPointer<UInt8>()
    var ai_next: CPointer<addrinfo> = CPointer<addrinfo>()
}

@When[os == "Windows"]
@C
struct addrinfo {
    var ai_flags: Int32 = 0
    var ai_family: Int32 = 0
    var ai_socktype: Int32 = 0
    var ai_protocol: Int32 = 0
    var ai_addrlen: UInt64 = 0
    var ai_canonname: CPointer<UInt8> = CPointer<UInt8>()
    var ai_addr: CPointer<sockaddr_in> = CPointer<sockaddr_in>()
    var ai_next: CPointer<addrinfo> = CPointer<addrinfo>()
}

@C
struct sockaddr {
    var sa_family: UInt16 = 0
    var sa_data: CPointer<Int8> = CPointer<Int8>()
}

@C
struct sockaddr_in {
    var sin_family: Int16 = 0
    var sin_port: UInt16 = 0
    var sin_addr: UInt32 = 0
    var sin_zero: UInt64 = 0
}

@C
struct in6_addr {
    var u6_addr8_1: UInt8 = 0
    var u6_addr8_2: UInt8 = 0
    var u6_addr8_3: UInt8 = 0
    var u6_addr8_4: UInt8 = 0
    var u6_addr8_5: UInt8 = 0
    var u6_addr8_6: UInt8 = 0
    var u6_addr8_7: UInt8 = 0
    var u6_addr8_8: UInt8 = 0
    var u6_addr8_9: UInt8 = 0
    var u6_addr8_10: UInt8 = 0
    var u6_addr8_11: UInt8 = 0
    var u6_addr8_12: UInt8 = 0
    var u6_addr8_13: UInt8 = 0
    var u6_addr8_14: UInt8 = 0
    var u6_addr8_15: UInt8 = 0
    var u6_addr8_16: UInt8 = 0
}

@C
struct sockaddr_in6 {
    var sin6_family: Int16 = 0
    var sin6_port: UInt16 = 0
    var sin6_flowinfo: UInt32 = 0
    var sin6_addr: in6_addr = in6_addr()
    var sin6_scope_id: UInt32 = 0
}

foreign func getaddrinfo(
    node: CPointer<UInt8>,
    service: CPointer<UInt8>,
    hints: CPointer<addrinfo>,
    res: CPointer<CPointer<addrinfo>>
): Int32
foreign func freeaddrinfo(pAddrInfo: CPointer<addrinfo>): Unit
foreign func malloc(size: Int64): CPointer<Int8>
foreign func free(ptr: CPointer<UInt8>): Unit

@When[os == "Windows"]
foreign func WSAStartup(wVersionRequested: UInt16, lpWSAData: CPointer<UInt8>): Int32

@When[os == "Windows"]
foreign func WSACleanup(): Int32

let AF_INET: Int32 = 2

@When[os == "Windows"]
let AF_INET6: Int32 = 23

@When[os != "Windows"]
let AF_INET6: Int32 = 10

func http_SOCKET_ConvertAddrPtr(res: CPointer<addrinfo>): CPointer<UInt8> {
    let arraddrlen = 400
    var tmpaddr = Array<UInt8>(arraddrlen, item: 0)
    var ip4cnt = 0
    var ip6cnt = 0
    let ip4bytes = 5
    let ip6bytes = 17
    var cur = CPointer<addrinfo>()
    var useCnt = 0
    let nullptr = CPointer<UInt8>()

    cur = res
    while (cur.isNotNull()) {
        var info = unsafe { cur.read() }
        if (info.ai_addr.isNull()) {
            continue
        }

        if (info.ai_family == AF_INET) {
            useCnt = ip4bytes
        } else {
            useCnt = ip6bytes
        }

        if (ip4cnt * ip4bytes + ip6cnt * ip6bytes + 1 > arraddrlen - useCnt) {
            LOG.debug("Error: The number of IP exceeds the resolution range")
            return nullptr
        }

        if (info.ai_family == AF_INET) {
            let BYTE_WIDTH = 8
            var pAddr: CPointer<sockaddr_in> = CPointer<sockaddr_in>(info.ai_addr)
            var addr: sockaddr_in = unsafe { pAddr.read() }
            tmpaddr[ip4cnt * ip4bytes + ip6cnt * ip6bytes + 1] = UInt8(ip4bytes - 1)
            var ip: UInt32 = addr.sin_addr
            for (i in 1..ip4bytes) {
                tmpaddr[ip4cnt * ip4bytes + ip6cnt * ip6bytes + i + 1] = UInt8(ip & 0xFF)
                ip = ip >> BYTE_WIDTH
            }
            ip4cnt++
        }

        if (info.ai_family == AF_INET6) {
            var pAddr: CPointer<sockaddr_in6> = CPointer<sockaddr_in6>(info.ai_addr)
            var addr: sockaddr_in6 = unsafe { pAddr.read() }
            tmpaddr[ip4cnt * ip4bytes + ip6cnt * ip6bytes + 1] = UInt8(ip6bytes - 1)
            var ip: in6_addr = addr.sin6_addr

            tmpaddr[ip4cnt * ip4bytes + ip6cnt * ip6bytes + 2] = ip.u6_addr8_1
            tmpaddr[ip4cnt * ip4bytes + ip6cnt * ip6bytes + 3] = ip.u6_addr8_2
            tmpaddr[ip4cnt * ip4bytes + ip6cnt * ip6bytes + 4] = ip.u6_addr8_3
            tmpaddr[ip4cnt * ip4bytes + ip6cnt * ip6bytes + 5] = ip.u6_addr8_4
            tmpaddr[ip4cnt * ip4bytes + ip6cnt * ip6bytes + 6] = ip.u6_addr8_5
            tmpaddr[ip4cnt * ip4bytes + ip6cnt * ip6bytes + 7] = ip.u6_addr8_6
            tmpaddr[ip4cnt * ip4bytes + ip6cnt * ip6bytes + 8] = ip.u6_addr8_7
            tmpaddr[ip4cnt * ip4bytes + ip6cnt * ip6bytes + 9] = ip.u6_addr8_8
            tmpaddr[ip4cnt * ip4bytes + ip6cnt * ip6bytes + 10] = ip.u6_addr8_9
            tmpaddr[ip4cnt * ip4bytes + ip6cnt * ip6bytes + 11] = ip.u6_addr8_10
            tmpaddr[ip4cnt * ip4bytes + ip6cnt * ip6bytes + 12] = ip.u6_addr8_11
            tmpaddr[ip4cnt * ip4bytes + ip6cnt * ip6bytes + 13] = ip.u6_addr8_12
            tmpaddr[ip4cnt * ip4bytes + ip6cnt * ip6bytes + 14] = ip.u6_addr8_13
            tmpaddr[ip4cnt * ip4bytes + ip6cnt * ip6bytes + 15] = ip.u6_addr8_14
            tmpaddr[ip4cnt * ip4bytes + ip6cnt * ip6bytes + 16] = ip.u6_addr8_15
            tmpaddr[ip4cnt * ip4bytes + ip6cnt * ip6bytes + 17] = ip.u6_addr8_16

            ip6cnt++
        }

        cur = info.ai_next
    }

    if (ip4cnt != 0 || ip6cnt != 0) {
        tmpaddr[0] = UInt8(ip4cnt + ip6cnt)
        var ret = CPointer<UInt8>(unsafe { malloc(ip4cnt * ip4bytes + ip6cnt * ip6bytes + 1) })
        if (ret.isNull()) {
            return nullptr
        }

        for (i in 0..ip4cnt * ip4bytes + ip6cnt * ip6bytes + 1) {
            unsafe { ret.write(i, tmpaddr[i]) }
        }

        return ret
    }

    return nullptr
}

@When[os == "Windows"]
func WSAStartup4cj(): Int32 {
    var wVersionRequested: UInt16 = UInt16(2 & 0xff | (2 & 0xff) << 8)
    var wsaData = unsafe { CPointer<UInt8>(malloc(408)) }
    if (wsaData.isNull()) {
        return -1
    }
    var ret = unsafe { WSAStartup(wVersionRequested, wsaData) }
    unsafe { free(CPointer<UInt8>(wsaData)) }
    if (ret != 0) {
        LOG.debug("WSAStartup failed: ${ret}")
    }
    return ret
}

@When[os != "Windows"]
func WSAStartup4cj(): Int32 {
    return 0
}

@When[os == "Windows"]
func WSACleanup4cj(): Int32 {
    unsafe { WSACleanup() }
}

@When[os != "Windows"]
func WSACleanup4cj(): Int32 {
    0
}

let AI_PASSIVE: Int32 = 0x1
let AI_ALL: Int32 = 0x10

func http_SOCKET_GetAddrInfo(net: UInt8, node: CString): CPointer<UInt8> {
    var nullptr = CPointer<UInt8>()
    var service = CPointer<UInt8>()

    var ret = WSAStartup4cj()
    if (ret != 0) {
        return nullptr
    }

    var hints = addrinfo()
    hints.ai_flags = AI_PASSIVE | AI_ALL
    hints.ai_protocol = Int32(net)
    var pHints = unsafe { CPointer<addrinfo>(malloc(48)) }
    if (pHints.isNull()) {
        return nullptr
    }
    unsafe { pHints.write(hints) }

    var res = CPointer<addrinfo>()
    var pRes = unsafe { CPointer<CPointer<addrinfo>>(malloc(8)) }
    if (pRes.isNull()) {
        return nullptr
    }
    unsafe { pRes.write(res) }

    ret = unsafe { getaddrinfo(node.getChars(), service, pHints, pRes) }
    unsafe { free(CPointer<UInt8>(pHints)) }
    if (ret != 0) {
        LOG.debug("GetAddrInfo failed")
        WSACleanup4cj()
        unsafe { free(CPointer<UInt8>(pRes)) }
        return nullptr
    }

    res = unsafe { pRes.read() }
    var addr = http_SOCKET_ConvertAddrPtr(res)
    unsafe {
        freeaddrinfo(res)
        free(CPointer<UInt8>(pRes))
    }

    WSACleanup4cj()

    return addr
}

public interface Dns {
    func lookup(domain: String): ArrayList<(SocketAddressKind, Array<UInt8>)>
}

class SystemDns <: Dns {
	public func lookup(domain: String): ArrayList<(SocketAddressKind, Array<UInt8>)> {
        //default tcp
        return resolveDomain(TCP, domain)
	}
}
