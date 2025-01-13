/**
 * Created on 2024/12/31
 */
package ohos_app_cangjie_OkRequest

import ohos_app_cangjie_OkRequest.okhttp.*
import std.time.Duration
import ohos.ark_interop.*
import ohos.ark_interop_macro.*
import net.tls.*
import crypto.x509.X509Certificate
import std.collection.ArrayList



@Interop[ArkTS]
public class ArkHttpClient {

    @Interop[ArkTS, Invisible]
    let realClient: HttpClient

    public init(timeout: Int64, maxConnections: Int64, protocols: Option<JSArrayEx<String>>, arkTlsConfig: Option<ArkTlsConfig>) {
        let connectionPool = ConnectionPool(maxIdleConnections: maxConnections)
        let builder = HttpClient.builder()
            .connectTimeout(Duration.second * timeout)
            .readTimeout(Duration.second * timeout)
            .writeTimeout(Duration.second * timeout)
            .connectionPool(Some(connectionPool))
        
        let clientProtocols = match (protocols) {
            case Some(protocols) =>
                let pArrayList = ArrayList<String>()
                for (i in 0..protocols.size) {
                    let protocol = protocols.get(i)
                    match (protocol) {
                    	case Some(protocol) => pArrayList.append(protocol)
                        case None => ()
                    }
                }
                if (pArrayList.isEmpty()) {
                    pArrayList.append(Protocol.get("HTTP/1.1").toString())
                }
                pArrayList
            case None => ArrayList<String>([Protocol.get("HTTP/1.1").toString()])
        }
        builder.protocols(clientProtocols)

        let tlsConfig = match (arkTlsConfig) {
            case Some(arkTlsConfig) =>
                var tlsConfig = TlsClientConfig()

                let verifyMode = match (arkTlsConfig.verifyMode) {
                    case "All" => CertificateVerifyMode.TrustAll
                    case "Custom" =>
                        match (arkTlsConfig.pem) {
                            case Some(pem) => CustomCA(X509Certificate.decodeFromPem(pem))
                            case None => CertificateVerifyMode.Default
                        }
                    case _ => CertificateVerifyMode.Default
                }
                tlsConfig.verifyMode = verifyMode
//                tlsConfig.alpnProtocolsList = clientProtocols.toArray()
                tlsConfig
            case None => None<TlsClientConfig>
        }
        match (tlsConfig) {
            case Some(tlsConfig) => builder.tlsConfig(tlsConfig)
            case None => ()
        }


        realClient = builder
            .build()
    }

    @Interop[ArkTS, Invisible]
    public func getRealClient(): HttpClient {
        return realClient
    }
}


//public interface IResponseBodyIterceptor {
//    func intercept(body: ArkResponseBody): Unit
//}
//
//public interface IRequestHeaderIterceptor {
//    func intercept(header: JSHashMapEx<String, String>): Unit
//}
//
//public class ResponseBodyIterceptor <: Interceptor {
//	let interceptor: IResponseBodyIterceptor
//    public init(interceptor: IResponseBodyIterceptor) {
//    	this.interceptor = interceptor
//    }
//    public func intercept(chain: Chain): Response {
//        let request = chain.getRequest()
//        let response = chain.proceed(request)
//        let arkResponse = response.toArkResponse()
//        arkResponse.getBody()
//        interceptor.intercept(arkResponse.get)
//        return response.newBuilder().body(body: Option<ResponseBody>).build()
//    }
//}
//
//public class RequestHeaderInterceptor <: Interceptor {
//    let interceptor: IRequestHeaderIterceptor
//    public init(interceptor: IRequestHeaderIterceptor) {
//    	this.interceptor = interceptor
//    }
//    public func intercept(chain: Chain): Response {
//        let request = chain.getRequest()
//        request.newBuilder()
//        return chain.proceed(request)
////        let response =  chain.proceed(chain.getRequest())
////        response.toArkResponse()
////        return response.newBuilder().body(body: Option<ResponseBody>).build()
//    }
//}
