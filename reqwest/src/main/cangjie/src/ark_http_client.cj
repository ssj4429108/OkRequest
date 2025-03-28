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
import net.http.ClientBuilder
import net.http.Client



@Interop[ArkTS]
public class ArkHttpClient {

    @Interop[ArkTS, Invisible]
    let realClient: Client
    public init(timeout: Int64, maxConnections: Int64, protocols: Option<JSArrayEx<String>>, arkTlsConfig: Option<ArkTlsConfig>) {
        let connectionPool = ConnectionPool(maxIdleConnections: maxConnections)
        let builder = ClientBuilder()
            .maxConcurrentStreams(UInt32(maxConnections))
            .readTimeout(Duration.second * timeout)
            .writeTimeout(Duration.second * timeout)

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
    public func getRealClient(): Client {

        return realClient
    }
}