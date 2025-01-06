/**
 * Created on 2024/12/31
 */
package ohos_app_cangjie_reqwest

import ohos.ark_interop.*
import ohos.ark_interop_macro.*
import ohos_app_cangjie_reqwest.okhttp.*

@Interop[ArkTS]
public class ArkResponse <: ToString {
    public let url: String
    let protocol: String
    public let code: Int64
    public let body: Option<ArkResponseBody>
    public let message: String

    public init(url: String, protocol: String, code: Int64, body: Option<ArkResponseBody>, message: String) {
        this.url = url
        this.protocol = protocol
        this.code = code
        this.body = body
        this.message = message
    }

    @Interop[ArkTS, Invisible]
    public func getCode(): Int64 {
        return code
    }

    @Interop[ArkTS, Invisible]
    func getBody(): Option<ArkResponseBody> {
        return body
    }

    @Interop[ArkTS, Invisible]
    public func getMessage(): String {
        return message
    }

    @Interop[ArkTS, Invisible]
    public func getUrl(): String {
        return url
    }

    @Interop[ArkTS, Invisible]
    public func text(): String {
        return match (getBody()) {
            case Some(body) => body.text()
            case None => ""
        }
    }

    @Interop[ArkTS, Invisible]
    public func bytes(): Option<Array<Byte>> {
        return match (getBody()) {
            case Some(body) => body.getData()
            case None => None
        }
    }

    /**
     * The Function is toString
     *
     * @return Type of String
     * @since 0.29.3
     */
    @Interop[ArkTS, Invisible]
    public func toString(): String {
        return "Response{protocol=${protocol}, code=${code}, message=${message}, url=${url}}"
    }

    public prop isSuccess: Bool {
        get() {
        	return code >= 200 && code < 300
        }
    }

}


extend Response {
    public func toArkResponse(): ArkResponse {
        let arkResponseBody = match (this.getBody()) {
            case Some(body) =>
                let contentType = match (body.getContentType()) {
                    case Some(contentType) => contentType.toString()
                    case None => ""
                }
                ArkResponseBody(contentType, body.getContentLength(), body.getBytes())
            case None => None<ArkResponseBody>
        }
        return ArkResponse(this.getRequest().getUrl().toString(), this.getProtocol().toString(), this.getCode(),
            arkResponseBody, this.getMessage())
    }
}
