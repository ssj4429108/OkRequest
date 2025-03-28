/**
 * Created on 2024/12/31
 */
package ohos_app_cangjie_OkRequest

import ohos.ark_interop.*
import ohos.ark_interop_macro.*
import ohos_app_cangjie_OkRequest.okhttp.*
import std.collection.forEach
import std.collection.ArrayList
import crypto.x509.Key
import std.io.ByteArrayStream
import encoding.json.stream.JsonWriter
import ohos.hilog.Hilog
import encoding.json.stream.WriteConfig
import net.http.HttpResponse

@Interop[ArkTS]
public class ArkResponse <: ToString {
    public let url: String
    let protocol: String
    public let code: Int64
    public let body: Option<ArkResponseBody>
    public let message: String
    public let headers: Option<String>

    public init(url: String, protocol: String, code: Int64, headers: Option<String>, body: Option<ArkResponseBody>, message: String) {
        this.url = url
        this.protocol = protocol
        this.code = code
        this.headers = headers
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


extend HttpResponse {
    public func toArkResponse(): ArkResponse {
        let respHeaders = this.trailers
        var headers = None<String>

        if (!respHeaders.iterator().isEmpty()) {
            let stream = ByteArrayStream()
            let writer = JsonWriter(stream)
            writer.startArray()
            respHeaders.iterator().forEach { header =>
                let name = header[0]
                let value = String.join(header[1].toArray(), delimiter: ";")
                writer.startObject()
                writer.writeName('name').writeValue(name)
                writer.writeName('value').writeValue(value)
                writer.endObject()
            }
            writer.endArray()
            writer.flush()
            headers = Some(String.fromUtf8(stream.readToEnd()))
        }
        let contentLength = bodySize.getOrThrow()
        let buffer = Array<Byte>(contentLength, item: 0)
        let length = body.read(buffer)
        let arkResponseBody = if (length > 0) {
            let contentType = String.join(this.trailers.get("Content-Type").toArray(), delimiter: ";")
            ArkResponseBody(contentType, contentLength, buffer)
        } else {
            None<ArkResponseBody>
        }
        let request = this.request.getOrThrow()
        return ArkResponse(request.url.toString(), this.version.toString(), Int64(this.status), headers,
            arkResponseBody, "")
    }
}
