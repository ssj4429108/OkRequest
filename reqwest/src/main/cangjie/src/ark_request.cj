/**
 * Created on 2024/12/31
 */
package ohos_app_cangjie_OkRequest

import std.collection.ArrayList
import ohos_app_cangjie_OkRequest.okhttp.*
import encoding.url.URL
internal import ohos.ark_interop.*
import ohos.ark_interop_macro.*
import ohos.hilog.Hilog
import encoding.json.JsonValue
import std.socket.SocketAddressKind

@Interop[ArkTS]
public class ArkHeader <: ToString {
    public var name: String = ""
    public var value: String = ""
    public init(name: String, value: String) {
        this.name = name
        this.value = value
    }

    @Interop[ArkTS, Invisible]
    public func toString(): String {
        return "Header{name=${name}, value=${value}"
    }
}



@Interop[ArkTS, Async]
public func send(client: ArkHttpClient, request: ArkRequest): Option<ArkResponse> {
    request.requestFuture = spawn {
        let realRequest = request.buildRealRequest(client.cacheControl)
        let response = try {
            client.getRealClient().newCall(realRequest).execute()
        } catch (e: Exception) {
            Hilog.error(2, "ok-request", "response error: ${e}")
            throw e
        }
        request.cacheDns()
        if (Thread.currentThread.hasPendingCancellation) {
            return None<ArkResponse>
        }
        return response.toArkResponse()
    }
    return match (request.requestFuture) {
        case Some(requestFuture) => requestFuture.get()
        case None => None
    }
}

@Interop[ArkTS]
public func sendSync(client: ArkHttpClient, request: ArkRequest): Option<ArkResponse> {
    let realRequest = request.buildRealRequest(client.cacheControl)
    let response = try {
        client.getRealClient().newCall(realRequest).execute()
    } catch (e: Exception) {
        Hilog.error(2, "ok-request", "response error: ${e}")
        throw e
    }

    request.cacheDns()
    if (Thread.currentThread.hasPendingCancellation) {
        return None<ArkResponse>
    }
    return response.toArkResponse()
}

@Interop[ArkTS]
public func cancel(request: ArkRequest): Unit {
    match (request.requestFuture) {
        case Some(future) => future.cancel()
        case None => ()
    }
}

@Interop[ArkTS]
public class ArkRequest {
    var url: String = ""
    var method: Option<String> = None
    var headers: Option<JSArrayEx<ArkHeader>> = None
    var mediaType: String = "application/json; charset=utf-8"
    var body: Option<Array<Byte>> = None
    var dns: Option<String> = None

    private var realHeaders: Option<ArrayList<ArkHeader>> = None<ArrayList<ArkHeader>>

    private var realAddressInfo: Option<ArrayList<(SocketAddressKind, Array<UInt8>)>> = None

    @Interop[ArkTS, Invisible]
    var requestFuture: Option<Future<Option<ArkResponse>>> = None<Future<Option<ArkResponse>>>
    public init(url: String, method: Option<String>, headers: Option<JSArrayEx<ArkHeader>>, mediaType: String,
        body: Option<Array<Byte>>, dns: Option<String>) {
        this.url = url
        this.method = method
        this.headers = headers
        this.mediaType = mediaType
        this.body = body
        this.dns = dns
        match (headers) {
            case Some(headers) =>
                let headerArray = ArrayList<ArkHeader>()
                for (i in 0..headers.size) {
                    let header = headers.get(i)
                    match (header) {
                        case Some(header) => headerArray.append(header)
                        case None => ()
                    }
                }
                realHeaders = headerArray
            case None => ()
        }
        match (dns) {
            case Some(json) =>
                let temps = JsonValue.fromStr(json).asArray().getItems()
                let result = ArrayList<(SocketAddressKind, Array<UInt8>)>()
                for (i in 0..temps.size) {
                    let item = temps[i]
                    let obj = item.asObject()
                    let sockectAddressKind = match (obj.get('family')) {
                        case Some(family) => family.asInt().getValue()
                        case None => -1
                    }
                    let addressKind = match (sockectAddressKind) {
                        case 1 => SocketAddressKind.IPv4
                        case 2 => SocketAddressKind.IPv6
                        case _ => SocketAddressKind.Unix
                    }

                    let address = obj.get('address')
                    match (address) {
                        case Some(address) =>
                            let ips = address.asString().getValue().split('.', removeEmpty: true).toArray()
                            let arr = Array<UInt8>()
                            for (j in 0..ips.size) {
                                let ipSplit = ips[j] as UInt8
                                match (ipSplit) {
                                    case Some(ipSplit) => arr[j] = ipSplit
                                    case None => ()
                                }
                            }
                            result.append((addressKind, arr))
                        case None => continue
                    }
                }
                this.realAddressInfo = result
            case None => ()
        }
    }

    @Interop[ArkTS, Invisible]
    public func cacheDns() {
        match (realAddressInfo) {
            case Some(addressInfo) =>
                let domain = URL.parse(url).hostName
                SystemDns.instance().addDnsCache(domain, addressInfo)
            case None => ()
        }
    }

    @Interop[ArkTS, Invisible]
    private func bodyMethod(method: String, requestBuilder: RequestBuilder) {
        let realBody = match (body) {
            case Some(body) => RealRequestBody.create(MediaType.get(mediaType), body)
            case None => None<RequestBody>
        }
        requestBuilder.method(method, body: realBody)
    }
    @Interop[ArkTS, Invisible]
    public func buildRealRequest(cacheControl: Option<ArkCacheControl>): Request {
        let requestBuilder = Request.builder()
        let url = URL.parse(url)
        requestBuilder.url(url)
        match (method) {
            case Some(method) => match (method) {
                case "GET" => requestBuilder.method(method, body: None)
                case "HEAD" => requestBuilder.method(method, body: None)
                case "POST" => bodyMethod(method, requestBuilder)
                case "PUT" => bodyMethod(method, requestBuilder)
                case "DELETE" => bodyMethod(method, requestBuilder)
                case "PATCH" => bodyMethod(method, requestBuilder)
                case "PROPPATCH" => bodyMethod(method, requestBuilder)
                case "REPORT" => bodyMethod(method, requestBuilder)
                case _ => requestBuilder.method("GET", body: None)
            }
            case None => ()
        }

        match (realHeaders) {
            case Some(headers) =>
                let headerBuilder = Header()

                for (i in 0..headers.size) {
                    let header = headers.get(i)
                    match (header) {
                        case Some(header) => headerBuilder.add(header.name, header.value)
                        case None => ()
                    }
                }
                if (!headers.isEmpty()) {
                    requestBuilder.header(headerBuilder)
                }
            case None => ()
        }
        match (cacheControl) {
        	case Some(arkCacheControl) =>
                let cacheBuilder = CacheControlBuilder()
                if (arkCacheControl.immutableBuild) {
                    cacheBuilder.immutable()
                }
                if (arkCacheControl.noTransformBuild) {
                    cacheBuilder.noTransform()
                }
                if (arkCacheControl.onlyIfCachedBuild) {
                    cacheBuilder.onlyIfCached()
                }
                if (arkCacheControl.noStoreBuild) {
                    cacheBuilder.noStore()
                }
                if (arkCacheControl.noTransformBuild) {
                    cacheBuilder.noTransform()
                }
                cacheBuilder.minFresh(arkCacheControl.minFreshSeconds)
                cacheBuilder.maxAge(arkCacheControl.maxAgeSeconds)
                cacheBuilder.maxStale(arkCacheControl.maxStaleSeconds)
                requestBuilder.cacheControl(cacheBuilder.build())
            case None => ()
        }
        return requestBuilder.build()
    }
}
