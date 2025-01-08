/**
 * Created on 2024/12/31
 */
package ohos_app_cangjie_OkRequest

import ohos_app_cangjie_OkRequest.okhttp.*
import std.time.Duration
import ohos.ark_interop.JSHashMapEx
import ohos.ark_interop.*
import ohos.ark_interop_macro.*
import net.tls.TlsClientConfig

@Interop[ArkTS]
public class ArkHttpClient {
    let timeout: Int64
    let maxConnections: Int64

    @Interop[ArkTS, Invisible]
    let realClient: HttpClient

    public init(timeout: Int64, maxConnections: Int64) {
        this.timeout = timeout
        this.maxConnections = maxConnections
        let connectionPool = ConnectionPool(maxIdleConnections: maxConnections)
        let tlsConfig = TlsClientConfig()
        realClient = HttpClient.builder()
            .connectTimeout(Duration.second * timeout)
            .readTimeout(Duration.second * timeout)
            .writeTimeout(Duration.second * timeout)
            .connectionPool(Some(connectionPool))
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
