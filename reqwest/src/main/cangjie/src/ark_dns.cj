/**
 * Created on 2025/1/9
 */
package ohos_app_cangjie_OkRequest

import std.socket.SocketAddressKind
import std.collection.ArrayList
import ohos_app_cangjie_OkRequest.okhttp.Dns

//public interface IArkDns {
//    public func lookup(domain: String): JSArrayEx<ArkInetAddress>
//}

//public class ArkDns {
//    let iDns: IArkDns
//    public init(iDns: IArkDns) {
//        this.iDns = iDns
//    }
//}

public class ArkInetAddress {
    let socketAddressKind: String
    let ip: JSArrayEx<UInt8>
    public init(socketAddressKind: String, ip: JSArrayEx<UInt8>) {
    	this.socketAddressKind = socketAddressKind
        this.ip = ip
    }
}

//class ArkDns2Dns <: Dns {
//    private let arkDns: ArkDns
//    init(arkDns: ArkDns) {
//        this.arkDns = arkDns
//    }
//    public func lookup(domain: String): ArrayList<(SocketAddressKind, Array<UInt8>)> {
//        let temps = arkDns.iDns.lookup(domain)
//        let result = ArrayList<(SocketAddressKind, Array<UInt8>)>()
//        for (i in 0..temps.size) {
//            let item = temps[i]
//            let addressKind = match (item.socketAddressKind) {
//            	case 'IPv4' => SocketAddressKind.IPv4
//                case 'IPv6' => SocketAddressKind.IPv6
//                case _ => SocketAddressKind.Unix
//            }
//            let arr = Array<UInt8>()
//            for (j in 0..item.ip.size) {
//                arr[j] = item.ip[j]
//            }
//            result.append((addressKind, arr))
//        }
//        return result
//	}
//}