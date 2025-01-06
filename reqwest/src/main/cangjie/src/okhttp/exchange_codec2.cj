/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2022-2024. All rights resvered.
 */

/**
 * @file The file manage ExchangeCodec.
 */

package ohos_app_cangjie_reqwest.okhttp

/**
 * The class is Http2ExchangeCodec
 * @author luoyukai4
 * @since 0.34.3
 */
public class Http2ExchangeCodec <: ExchangeCodec {
    private static let CONNECTION = "connection"
    private static let HOST = "host"
    private static let KEEP_ALIVE = "keep-alive"
    private static let PROXY_CONNECTION = "proxy-connection"
    private static let TRANSFER_ENCODING = "transfer-encoding"
    private static let TE = "te"
    private static let ENCODING = "encoding"
    private static let UPGRADE = "upgrade"
    public static let RESPONSE_STATUS = ":status"
    public static let TARGET_METHOD = ":method"
    public static let TARGET_PATH = ":path"
    public static let TARGET_SCHEME = ":scheme"
    public static let TARGET_AUTHORITY = ":authority"

    private static let HTTP_2_SKIPPED_REQUEST_HEADERS: Array<String> = [
        CONNECTION,
        HOST,
        KEEP_ALIVE,
        PROXY_CONNECTION,
        TE,
        TRANSFER_ENCODING,
        ENCODING,
        UPGRADE,
        TARGET_METHOD,
        TARGET_PATH,
        TARGET_SCHEME,
        TARGET_AUTHORITY
    ]

    private static let HTTP_2_SKIPPED_RESPONSE_HEADERS: Array<String> = [
        CONNECTION,
        HOST,
        KEEP_ALIVE,
        PROXY_CONNECTION,
        TE,
        TRANSFER_ENCODING,
        ENCODING,
        UPGRADE
    ]

    private let realConnection: Connection
    private var canceled = false
    private var stream: Option<H2Stream> = Option<H2Stream>.None
    private let http2Connection: H2Connection
    private var client: HttpClient
    private let protocol: Protocol

    public init(client: HttpClient, realConnection: Connection, http2Connection: H2Connection) {
        this.client = client
        this.realConnection = realConnection
        this.http2Connection = http2Connection
        if (client.getProtocols().contains("h2_prior_knowledge")) {
            protocol = H2_PRIOR_KNOWLEDGE
        } else {
            protocol = HTTP_2
        }
    }

    public func readResponseHeaders(expectContinue: Bool): Option<ResponseBuilder> {
        let headers = stream.getOrThrow().takeHeaders()
        let res: ResponseBuilder = readHttp2HeadersList(headers, protocol)

        if (expectContinue && res.codeBuild == HttpStatusCode.STATUS_CONTINUE) {
            return Option<ResponseBuilder>.None
        }
        return res
    }

    public static func readHttp2HeadersList(headerBlock: Header, protocol: Protocol) {
        let res = Response.builder().protocol(protocol)
        let header: Header = Header()
        var hasStatus: Bool = false
        for ((k, v) in headerBlock) {
            if (k == RESPONSE_STATUS) {
                let statusLine = StatusLine.parse("HTTP/1.1 " + v[0])
                res.code(statusLine.code).message(statusLine.message)
                hasStatus = true
            } else if (!HTTP_2_SKIPPED_RESPONSE_HEADERS.contains(k)) {
                header.add(k, v[0])
            }
        }
        if (!hasStatus) {
            throw ProtocolException("Expected ':status' header not present")
        }
        res.header(header)
        return res
    }

    public func getTrailers(): Header {
        return stream.getOrThrow().getTrailers()
    }

    public func reportedContentLength(response: Response): Int64 {
        return contentLength(response)
    }

    public func openResponseBodySource(_: Response): Source {
        return stream.getOrThrow().getSource()
    }

    public func getConnection(): Connection {
        return realConnection
    }

    public func cancel(): Unit {
        canceled = true
        if (has(stream)) {
            stream.getOrThrow().closeLater(ErrorCode.CANCEL)
        }
    }

    public func createRequestBody(_: Request): Sink {
        return stream.getOrThrow().getSink()
    }

    public func writeRequestHeaders(request: Request): Unit {
        if (has(stream)) {
            return
        }

        stream = http2Connection.newStream(request)

        if (canceled) {
            stream.getOrThrow().closeLater(ErrorCode.CANCEL)
            throw HttpException("Canceled")
        }
    }

    static func http2HeadersList(request: Request): ArrayList<HeaderField> {
        let result: ArrayList<HeaderField> = ArrayList<HeaderField>()
        result.append(HeaderField(TARGET_METHOD, request.getMethod()))
        let u = request.getUrl()
        let rawPath = if (u.rawPath.size > 0) {
            u.rawPath
        } else {
            "/"
        }
        let rawQuery = match (u.rawQuery) {
            case Some(v) => "?${v}"
            case _ => ""
        }
        result.append(HeaderField(TARGET_PATH, "${rawPath}${rawQuery}"))
        let host = request.getHeader("Host", "")

        if (host != "") {
            result.append(HeaderField(TARGET_AUTHORITY, host))
        }
        result.append(HeaderField(TARGET_SCHEME, request.getUrl().scheme))
        for ((k, v) in request.getHeaders()) {
            let name = k.toLower()
            if (!HTTP_2_SKIPPED_REQUEST_HEADERS.contains(name) || (k == TE && v[0] == "trailers")) {
                result.append(HeaderField(name, v[0]))
            }
        }
        return result
    }

    public func flushRequest() {
        http2Connection.flush()
    }

    public func finishRequest(): Unit {
        stream.getOrThrow().getSink().close()
    }
}
