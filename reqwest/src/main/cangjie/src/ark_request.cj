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
        let request = request.buildRealRequest()
        let response = client.getRealClient().newCall(request).execute()
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

    private var realHeaders: Option<ArrayList<ArkHeader>> = None<ArrayList<ArkHeader>>

    @Interop[ArkTS, Invisible]
    var requestFuture: Option<Future<Option<ArkResponse>>> = None<Future<Option<ArkResponse>>>
    public init(url: String, method: Option<String>, headers: Option<JSArrayEx<ArkHeader>>, mediaType: String, body: Option<Array<Byte>>) {
        this.url = url
        this.method = method
        this.headers = headers
        this.mediaType = mediaType
        this.body = body
        match (headers) {
            case Some(headers) =>
                let headerArray = ArrayList<ArkHeader>()
                for (i in 0..headers.size) {
                    let header = headers.get(i)
                    match (header) {
                        case Some(header) =>
                            headerArray.append(header)
                        case None => ()
                    }
                }
                realHeaders = headerArray
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
    public func buildRealRequest(): Request {
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
                        case Some(header) =>
                            headerBuilder.add(header.name, header.value)
                        case None => ()
                    }

                }
                if (!headers.isEmpty()) {
                    requestBuilder.header(headerBuilder)
                }
            case None => ()
        }
        return requestBuilder.build()
    }
}