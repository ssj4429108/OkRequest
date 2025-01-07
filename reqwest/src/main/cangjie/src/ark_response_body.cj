/**
 * Created on 2024/12/31
 */
package ohos_app_cangjie_OkRequest

import ohos.ark_interop.*
import ohos.ark_interop_macro.*

@Interop[ArkTS]
public class ArkResponseBody {
    public let data: Option<Array<Byte>>
    public let contentTypeString: String
    public var contentLength: Int64 = 0

    public init(contentType: String, contentLength: Int64, data: Option<Array<Byte>>) {
        this.contentTypeString = contentType
        this.contentLength = contentLength
    	this.data = data
    }

    @Interop[ArkTS, Invisible]
    public func getContentType(): String {
    	return contentTypeString
    }

    @Interop[ArkTS, Invisible]
    public func getContentLength(): Int64 {
    	return contentLength
    }

    @Interop[ArkTS, Invisible]
    public func getData(): Option<Array<Byte>> {
        return data
    }

    func text(): String {
        return match (getData()) {
        	case Some(data) => String.fromUtf8(data)
            case None => ""
        }
    }
}