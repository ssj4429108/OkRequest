/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2022-2024. All rights resvered.
 */

/**
 * @file
 * The file declares the Source impls.
 */

package ohos_app_cangjie_OkRequest.okhttp

abstract class AbstractSource <: Source {
    protected var closed: Bool = false
    protected let exchangeCode: Http1ExchangeCodec

    init(exchange: Http1ExchangeCodec) {
        this.exchangeCode = exchange
    }

    public open func read(bytes: ByteArrayStream, byteCount: Int64): Int64 {
        return exchangeCode.source.read(bytes, byteCount)
    }

    public open func isClosed(): Bool {
        return closed
    }
}

class FixedLengthSource <: AbstractSource {
    private var bytesRemaining: Int64

    init(length: Int64, exchange: Http1ExchangeCodec) {
        super(exchange)
        this.bytesRemaining = length

        if (bytesRemaining == 0) {
            exchangeCode.responseBodyComplete()
        }
    }

    public func read(bytes: ByteArrayStream, count: Int64): Int64 {
        var byteCount = count

        if (isClosed()) {
            throw IllegalStateException("closed")
        }

        if (bytesRemaining == 0) {
            return -1
        }

        if (byteCount > bytesRemaining) {
            byteCount = bytesRemaining
        }

        let read = super.read(bytes, byteCount)

        if (read == -1) {
            exchangeCode.getConnection().noExchanges()
            exchangeCode.responseBodyComplete()
            throw ProtocolException("unexpected end of stream")
        }

        bytesRemaining -= read

        if (bytesRemaining == 0) {
            exchangeCode.responseBodyComplete()
        }
        return read
    }

    public func close(): Unit {
        if (isClosed()) {
            return
        }

        if (bytesRemaining != 0 && !disCard(this)) {
            exchangeCode.getConnection().noExchanges()
            exchangeCode.responseBodyComplete()
        }

        closed = true
    }
}

class UnknownLengthSource <: AbstractSource {
    private var inputExhausted: Bool = false

    init(exchange: Http1ExchangeCodec) {
        super(exchange)
    }

    public func read(bytes: ByteArrayStream, byteCount: Int64): Int64 {
        if (isClosed()) {
            throw IllegalStateException("closed")
        }

        if (inputExhausted) {
            return -1
        }

        let buffer = exchangeCode.source
        let read = buffer.read(bytes, byteCount)

        if (read == -1) {
            inputExhausted = true
            exchangeCode.responseBodyComplete()
        }

        return read
    }

    public func close(): Unit {
        if (isClosed()) {
            return
        }

        if (!inputExhausted) {
            exchangeCode.responseBodyComplete()
        }

        closed = true
    }
}

class ChunkedSource <: Source {
    private let exchangeCode: Http1ExchangeCodec
    private static let NO_CHUNK_YET = -1
    private var closed: Bool = false
    private var hasMoreChunks: Bool = true
    private var url: URL
    private var bytesRemainingInChunk: Int64 = NO_CHUNK_YET

    init(url: URL, exchange: Http1ExchangeCodec) {
        this.url = url
        this.exchangeCode = exchange
    }

    public func read(bytes: ByteArrayStream, byteCount: Int64): Int64 {
        if (isClosed()) {
            throw IllegalStateException("closed")
        }

        if (!hasMoreChunks) {
            return -1
        }

        if (bytesRemainingInChunk == 0 || bytesRemainingInChunk == NO_CHUNK_YET) {
            readChunkSize()
            if (!hasMoreChunks) {
                return -1
            }
        }

        let buffer = exchangeCode.source
        let read = buffer.read(bytes, min(byteCount, bytesRemainingInChunk))

        if (read == -1) {
            exchangeCode.getConnection().noExchanges()
            exchangeCode.responseBodyComplete()
            throw ProtocolException("unexpected end of stream")
        }
        bytesRemainingInChunk -= read
        return read
    }

    private func readChunkSize() {
        if (bytesRemainingInChunk != NO_CHUNK_YET) {
            exchangeCode.source.skipBuffer(2)
        }

        let chunkedLength: String = exchangeCode.source.readUtf8LineStrict().trim()

        if (chunkedLength.size != 0) {
            match (HexStringToUInt64(chunkedLength.toUtf8Array())) {
                case Some(c) =>
                    if (c == 0) {
                        hasMoreChunks = false
                        exchangeCode.trailers = exchangeCode.readHeaders()
                        receiveHeaders(exchangeCode.client.getCookieJar(), url, exchangeCode.trailers)
                        exchangeCode.responseBodyComplete()
                    }
                    bytesRemainingInChunk = Int64(c)
                case None => throw ProtocolException("expected chunked size failed")
            }
        }
    }

    public func close(): Unit {
        if (isClosed()) {
            return
        }

        if (hasMoreChunks && !disCard(this)) {
            exchangeCode.getConnection().noExchanges()
            exchangeCode.responseBodyComplete()
        }

        closed = true
    }

    public func isClosed(): Bool {
        return closed
    }
}

class ResponseBodySource <: Source {
    private let contentLength: Int64
    private var bytesReceived: Int64 = 0
    private var completed: Bool = false
    private var closed: Bool = false
    private let exchange: Exchange
    private let source: Source

    init(source: Source, exchange: Exchange, contentLength: Int64) {
        this.source = source
        this.exchange = exchange
        this.contentLength = contentLength
        if (contentLength == 0) {
            complete(Option<HttpException>.None)
        }
    }

    public func read(bytes: ByteArrayStream, byteCount: Int64): Int64 {
        if (isClosed()) {
            throw IllegalStateException("closed")
        }

        try {
            let read = source.read(bytes, byteCount)
            if (read == -1) {
                complete(Option<HttpException>.None)
                return -1
            }
            let newBytesReceived = bytesReceived + read
            if (contentLength != -1 && newBytesReceived > contentLength) {
                throw ProtocolException("expected ${contentLength} bytes but received ${newBytesReceived}")
            }
            bytesReceived = newBytesReceived
            if (newBytesReceived == contentLength) {
                complete(Option<HttpException>.None)
            }
            return read
        } catch (e: HttpException) {
            complete(HttpException(e.message))
            throw e
        }
    }

    public func close(): Unit {
        if (isClosed()) {
            return
        }

        closed = true

        try {
            source.close()
            complete(Option<HttpException>.None)
        } catch (e: HttpException) {
            complete(HttpException(e.message))
            throw e
        }
    }
    public func isClosed(): Bool {
        return closed
    }

    private func complete(e: Option<HttpException>): Unit {
        if (completed) {
            return
        }

        completed = true
        exchange.bodyComplete(bytesReceived, true, false, e)
    }
}

class FramingSource <: Source {
    var finished: Bool = false
    var trailers: Option<Header> = Option<Header>.None
    var stream: Option<H2Stream> = Option<H2Stream>.None
    var maxByteCount: Int64
    let readBuffer = ByteArrayStream()
    let receiveBuffer = ByteArrayStream()
    var closed = false

    public init(maxByteCount: Int64) {
        this.maxByteCount = maxByteCount
    }

    public func read(bytes: ByteArrayStream, byteCount: Int64): Int64 {
        let h2Stream = stream.getOrThrow()

        if (byteCount < 0) {
            throw IllegalArgumentException("byteCount = ${byteCount} < 0")
        }

        while (true) {
            var readBytesDelivered = -1
            var errorExceptionToDeliver: Bool = false
            synchronized(h2Stream.mutex) {
                if (has(h2Stream.errorCode)) {
                    errorExceptionToDeliver = true
                }

                if (isClosed()) {
                    throw HttpException("stream closed")
                } else if (readBuffer.remainLength > 0) {
                    let arr = Array<Byte>(min(byteCount, readBuffer.remainLength), item: 0)
                    readBytesDelivered = readBuffer.read(arr)
                    bytes.write(arr)
                    h2Stream.unacknowledgedBytesRead += readBytesDelivered
                    if (!errorExceptionToDeliver && h2Stream.unacknowledgedBytesRead >=
                        h2Stream.cc.httpSettings.getInitialWindowSize() / 2) {
                        h2Stream.cc.writeWindowUpdateLater(h2Stream.id, h2Stream.unacknowledgedBytesRead)
                        h2Stream.unacknowledgedBytesRead = 0
                    }
                } else if (!finished && !errorExceptionToDeliver) {
                    h2Stream.mutex.wait()
                    continue
                }
            }

            if (readBytesDelivered != -1) {
                h2Stream.updateConnectionFlowControl(readBytesDelivered)
                return readBytesDelivered
            }

            if (errorExceptionToDeliver) {
                if (h2Stream.errorException == "") {
                    throw StreamResetException(h2Stream.errorCode.getOrThrow())
                } else {
                    throw HttpException("errorException")
                }
            }
            return -1
        }
        return -1
    }

    func receive(source: OkBuffer, length: Int64) {
        var byteCount = length
        while (byteCount > 0) {
            var finished: Bool
            var flowControlError: Bool
            synchronized(stream.getOrThrow().mutex) {
                finished = this.finished
                flowControlError = byteCount + readBuffer.remainLength > maxByteCount
            }

            if (flowControlError) {
                source.skipBuffer(byteCount)
                stream.getOrThrow().closeLater(ErrorCode.FLOW_CONTROL_ERROR)
                return
            }

            if (finished) {
                source.skipBuffer(byteCount)
                return
            }

            let read = source.read(receiveBuffer, byteCount)

            if (read == -1) {
                throw HttpException("EOF")
            }

            byteCount -= read
            var bytesDiscarded = 0
            synchronized(stream.getOrThrow().mutex) {
                if (isClosed()) {
                    bytesDiscarded = receiveBuffer.remainLength
                    receiveBuffer.clear()
                } else {
                    let wasEmpty = readBuffer.remainLength == 0
                    readBuffer.write(receiveBuffer.readToEnd())
                    if (wasEmpty) {
                        let mu = stream.getOrThrow().mutex
                        mu.notifyAll()
                    }
                }
            }

            if (bytesDiscarded > 0) {
                stream.getOrThrow().updateConnectionFlowControl(bytesDiscarded)
            }
        }
    }

    public func close(): Unit {
        let bytesDiscarded: Int64
        synchronized(stream.getOrThrow().mutex) {
            closed = true
            bytesDiscarded = readBuffer.remainLength
            readBuffer.clear()
            stream.getOrThrow().mutex.notifyAll()
        }

        if (bytesDiscarded > 0) {
            stream.getOrThrow().updateConnectionFlowControl(bytesDiscarded)
        }

        stream.getOrThrow().cancelStreamIfNecessary()
    }

    public func isClosed(): Bool {
        return closed
    }
}

class CacheWritingSource <: Source {
    var cacheRequestClosed: Bool = false
    var source: Source
    var cacheRequest: CacheRequest

    init(source: Source, cacheRequest: CacheRequest) {
        this.source = source
        this.cacheRequest = cacheRequest
    }

    public func read(bytes: ByteArrayStream, byteCount: Int64): Int64 {
        var bytesRead: Int64
        let cacheBody = RealBufferSink(cacheRequest)

        try {
            bytesRead = source.read(bytes, byteCount)
        } catch (e: IOException | HttpException) {
            if (!cacheRequestClosed) {
                cacheRequestClosed = true
                cacheRequest.abort()
            }
            throw e
        }

        if (bytesRead == -1) {
            if (!cacheRequestClosed) {
                cacheRequestClosed = true
                cacheBody.close() // The cache response is complete!
            }

            return -1
        }

        cacheBody.getBuffer().write(bytes.bytes())
        cacheBody.flush()
        return bytesRead
    }

    public func close(): Unit {
        if (!cacheRequestClosed && !disCard(this)) {
            cacheRequestClosed = true
            cacheRequest.abort()
        }

        source.close()
    }

    public func isClosed(): Bool {
        return source.isClosed()
    }
}
