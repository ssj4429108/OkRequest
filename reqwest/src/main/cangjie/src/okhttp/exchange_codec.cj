/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2022-2024. All rights resvered.
 */

/**
 * @file
 * The file declares the ExchangeCodec class.
 */

package ohos_app_cangjie_OkRequest.okhttp
import ohos.hilog.Hilog
import ohos_app_cangjie_OkRequest.okio.*

/* let member CRLF_CRLF type is Array<Byte> */
let CRLF_CRLF: Array<Byte> = "\r\n\r\n".toArray()

/* let member CRLF type is Array<Byte> */
let CRLF: Array<Byte> = "\r\n".toArray()

/* let member SP */
let SP = " ".toArray()

/* let member TRIM_BYTE type is Array<Byte> */
let TRIM_BYTE: Array<Byte> = SP
let CRLF_STR: String = "\r\n"
let CHAR_ZERO: UInt32 = 48
let UInt64ToHex: Array<UInt8> = "0123456789abcdef".toArray()

/**
 * The class is Http1ExchangeCodec
 * @author guo_tingtingtekla,luoyukai4
 * @since 0.29.3
 */
public class Http1ExchangeCodec <: ExchangeCodec {
    public static let CRLF: String = "\r\n"

    /* let member STATE_IDLE type is Int64 */
    static let STATE_IDLE: Int64 = 0 // Idle connections are ready to write request headers.

    /* let member STATE_OPEN_REQUEST_BODY type is Int64 */
    static let STATE_OPEN_REQUEST_BODY: Int64 = 1

    /* let member STATE_WRITING_REQUEST_BODY type is Int64 */
    static let STATE_WRITING_REQUEST_BODY: Int64 = 2

    /* let member STATE_READ_RESPONSE_HEADERS type is Int64 */
    static let STATE_READ_RESPONSE_HEADERS: Int64 = 3

    /* let member STATE_OPEN_RESPONSE_BODY type is Int64 */
    static let STATE_OPEN_RESPONSE_BODY: Int64 = 4

    /* let member STATE_READING_RESPONSE_BODY type is Int64 */
    private static let STATE_READING_RESPONSE_BODY: Int64 = 5

    /* let member STATE_CLOSED type is Int64 */
    static let STATE_CLOSED: Int64 = 6

    /* let member HEADER_LIMIT type is Int64 */
    private static let HEADER_LIMIT: Int64 = 256 * 1024

    /* var member realConnection type is Connection */
    private var realConnection: Connection

    /* var member state type is Int64 */
    var state: Int64 = STATE_IDLE

    /* var member client type is HttpClient */
    var client: HttpClient
    let sink: BufferedSink
    let source: BufferedSource
    private var headerLimit: Int64 = HEADER_LIMIT
    var trailers: Header = Header()

    /**
     * The Function is init constructor
     *
     * @param client of HttpClient
     * @param realConnection of Connection
     * @since 0.29.3
     */
    public init(
        client: HttpClient,
        realConnection: Connection,
        source: BufferedSource,
        sink: BufferedSink
    ) {
        this.client = client
        this.realConnection = realConnection
        this.source = source
        this.sink = sink
    }

    private func newKnownLengthSink(): Sink {
        if (state != STATE_OPEN_REQUEST_BODY) {
            throw IllegalStateException("state: ${state}")
        }

        state = STATE_WRITING_REQUEST_BODY
        return KnownLengthSink(this)
    }

    private func newChunkedSink() {
        if (state != STATE_OPEN_REQUEST_BODY) {
            throw IllegalStateException("state: ${state}")
        }

        state = STATE_WRITING_REQUEST_BODY
        return ChunkedSink(this)
    }

    private func newFixedLengthSource(length: Int64) {
        if (state != STATE_OPEN_RESPONSE_BODY) {
            throw IllegalStateException("state: ${state}")
        }

        state = STATE_READING_RESPONSE_BODY
        return FixedLengthSource(length, this)
    }

    private func newChunkedSource(url: URL): Source {
        if (state != STATE_OPEN_RESPONSE_BODY) {
            throw IllegalStateException("state: ${state}")
        }

        state = STATE_READING_RESPONSE_BODY
        return ChunkedSource(url, this)
    }

    private func newUnknownLengthSource(): Source {
        if (state != STATE_OPEN_RESPONSE_BODY) {
            throw IllegalStateException("state: ${state}")
        }

        state = STATE_READING_RESPONSE_BODY
        realConnection.noExchanges()
        return UnknownLengthSource(this)
    }

    public func flushRequest(): Unit {
        try {
            sink.flush()
        } catch (e: Exception) {
            realConnection.noExchanges()
            throw e
        }
    }

    public func finishRequest(): Unit {
        try {
            sink.flush()
        } catch (e: Exception) {
            realConnection.noExchanges()
            throw e
        }
    }

    public func getTrailers() {
        if (state != STATE_CLOSED) {
            throw IllegalStateException("too early; can't read the trailers yet")
        }
        return trailers
    }

    public func writeRequestHeaders(request: Request): Unit {
        let requestLine: String = RequestLine.get(request)
        writeRequest(request.getHeaders(), requestLine)
    }

    public func writeRequest(headers: Header, requestLine: String): Unit {
        if (state != STATE_IDLE) {
            throw IllegalStateException("state: ${state}")
        }
        var buffer: StringBuilder = StringBuilder()
        buffer.append(requestLine + CRLF)
        for ((ks, v) in headers) {
            // var k = HeaderDfaUtil.canonicalHeaderKey(ks)
            var k = ks
            buffer.append("${k}: ")
            var str = ""
            for (i in v) {
                str += ";${i}"
            }
            buffer.append(str[1..])
            buffer.append(CRLF)
        }

        buffer.append(CRLF_STR)
        sink.write(buffer.toString().toUtf8Array())
        state = STATE_OPEN_REQUEST_BODY
    }

    /**
     * The Function is readResponseHeaders
     *
     * @return Type of ResponseBuilder
     * @since 0.29.3
     */
    public func readResponseHeaders(expectContinue: Bool): Option<ResponseBuilder> {
        if (state != STATE_OPEN_REQUEST_BODY && state != STATE_READ_RESPONSE_HEADERS) {
            throw IllegalStateException("state: ${state}")
        }

        let responseBuilder: ResponseBuilder = Response.builder()
        let line: String = readHeaderLine()
        let statusLine: StatusLine = StatusLine.parse(line)
        responseBuilder.protocol(statusLine.protocol).code(statusLine.code).message(statusLine.message).header(
            readHeaders())

        if (expectContinue && statusLine.code == HttpStatusCode.STATUS_CONTINUE) {
            return None
        } else if (statusLine.code == HttpStatusCode.STATUS_CONTINUE) {
            state = STATE_READ_RESPONSE_HEADERS
            return responseBuilder
        }

        state = STATE_OPEN_RESPONSE_BODY
        return responseBuilder
    }

    private func readHeaderLine(): String {
        Hilog.info(3, "ok-request", "start read headerline: ${headerLimit}")
        let line = source.readUtf8LineStrict(headerLimit)
        headerLimit -= line.getOrThrow().size
        Hilog.info(3, "ok-request", "end read headerline: ${line.getOrThrow()}")
        return line.getOrThrow()
    }

    func readHeaders(): Header {
        let header: Header = Header()

        while (true) {
            var line = readHeaderLine()
            if (line.size == 0) {
                break
            }
            addLenient(header, line)
        }
        return header
    }

    public func createRequestBody(request: Request): Sink {
        let contentLength: Int64 = match (request.getBody()) {
            case Some(v) => v.getContentLength()
            case None => throw ProtocolException("no request body")
        }

        if ("chunked" == request.getHeader("Transfer-Encoding", "").toLower()) {
            return newChunkedSink()
        }

        if (contentLength != -1) {
            return newKnownLengthSink()
        }

        throw IllegalStateException("Cannot stream a request body without chunked encoding or a known content length!")
    }

    /*
     * The Function is reportedContentLength
     *
     * @return Type of Int64
     * @since 0.29.3
     */
    public func reportedContentLength(response: Response): Int64 {
        if (!hasBody(response)) {
            return 0
        }

        if ("chunked" == response.getHeader("Transfer-Encoding", "").toLower()) {
            return -1
        }

        match (response.getHeader("Content-Length")) {
            case Some(s) => match (Int64.tryParse(s)) {
                case Some(n) => return n
                case None => return -1
            }
            case None => return -1
        }
    }
    public func openResponseBodySource(response: Response): Source {
        if (!hasBody(response)) {
            return newFixedLengthSource(0)
        }

        if ("chunked" == response.getHeader("Transfer-Encoding", "").toLower()) {
            return newChunkedSource(response.getRequest().getUrl())
        }

        let contentLength: Int64 = contentLength(response)

        if (contentLength != -1) {
            return newFixedLengthSource(contentLength)
        }

        return newUnknownLengthSource()
    }

    /**
     * The Function is getConnection
     *
     * @return Type of Connection
     * @since 0.30.4
     */
    public func getConnection(): Connection {
        return this.realConnection
    }

    func responseBodyComplete() {
        if (state == STATE_CLOSED) {
            return
        }

        if (state != STATE_READING_RESPONSE_BODY) {
            throw IllegalStateException("state: ${state}")
        }

        state = STATE_CLOSED
    }

    /**
     * The Function is cancel
     *
     * @return Type of Unit
     * @since 0.30.4
     */
    public func cancel(): Unit {
        this.realConnection.cancel()
    }
}
