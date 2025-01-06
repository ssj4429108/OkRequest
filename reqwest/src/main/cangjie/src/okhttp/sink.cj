/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2022-2024. All rights resvered.
 */

/**
 * @file
 * The file declares the Sink impls.
 */

package ohos_app_cangjie_reqwest.okhttp

class KnownLengthSink <: Sink {
    private var closed: Bool = false
    private let exchange: Http1ExchangeCodec

    init(exchange: Http1ExchangeCodec) {
        this.exchange = exchange
    }

    public func write(bytes: Array<Byte>): Unit {
        exchange.sink.write(bytes)
    }

    public func flush(): Unit {
        if (closed) {
            return
        }
        exchange.sink.flush()
    }

    public func close(): Unit {
        if (closed) {
            return
        }
        closed = true
        exchange.state = Http1ExchangeCodec.STATE_READ_RESPONSE_HEADERS
    }
}

class ChunkedSink <: Sink {
    private var closed: Bool = false
    private let exchange: Http1ExchangeCodec

    init(exchange: Http1ExchangeCodec) {
        this.exchange = exchange
    }

    public func write(bytes: Array<Byte>): Unit {
        if (closed) {
            throw IllegalStateException("closed")
        }

        let dataSize = bytes.size

        if (dataSize == 0) {
            return
        }

        var lengthHex = UInt64ToHexString(UInt64(dataSize))
        this.exchange.sink.write(lengthHex)
        this.exchange.sink.write(CRLF)
        this.exchange.sink.write(bytes)
        this.exchange.sink.write(CRLF)
    }

    public func flush(): Unit {
        if (closed) {
            return
        }

        exchange.sink.flush()
    }

    public func close(): Unit {
        if (closed) {
            return
        }

        closed = true
        this.exchange.sink.write("0\r\n\r\n".toArray())
        
        exchange.state = Http1ExchangeCodec.STATE_READ_RESPONSE_HEADERS
    }
}

class RequestBodySink <: Sink {
    private var completed: Bool = false
    private var contentLength: Int64
    private var bytesReceived: Int64 = 0
    private var closed: Bool = false
    private let exchange: Exchange
    private let sink: Sink

    init(sink: Sink, contentLength: Int64, exchange: Exchange) {
        this.sink = sink
        this.contentLength = contentLength
        this.exchange = exchange
    }

    public func write(bytes: Array<Byte>): Unit {
        let byteCount = bytes.size
        if (closed) {
            throw IllegalStateException("closed")
        }

        if (contentLength != -1 && bytesReceived + byteCount > contentLength) {
            throw ProtocolException("expected ${contentLength} bytes but received ${bytesReceived + byteCount}")
        }

        try {
            sink.write(bytes)
            this.bytesReceived += byteCount
        } catch (e: HttpException) {
            complete(HttpException(e.message))
            throw e
        }
    }
    public func flush(): Unit {
        try {
            sink.flush()
        } catch (e: HttpException) {
            complete(HttpException(e.message))
            throw e
        }
    }
    public func close(): Unit {
        if (closed) {
            return
        }

        closed = true
        if (contentLength != -1 && bytesReceived != contentLength) {
            throw ProtocolException("unexpected end of stream")
        }

        try {
            sink.close()
            complete(Option<HttpException>.None)
        } catch (e: HttpException) {
            complete(HttpException(e.message))
            throw e
        }
    }

    private func complete(e: Option<HttpException>): Unit {
        if (completed) {
            return
        }

        completed = true
        exchange.bodyComplete(bytesReceived, false, true, e)
    }
}

public class RealBufferSink <: Sink {
    var closed: Bool = false
    let sink: Sink
    private var buffer: ByteArrayStream = ByteArrayStream()

    public init(sink: Sink) {
        this.sink = sink
    }

    public func write(bytes: Array<Byte>): Unit {
        if (closed) {
            throw IllegalStateException("closed")
        } else {
            buffer.write(bytes)
        }
    }

    public func flush(): Unit {
        if (closed) {
            throw IllegalStateException("closed")
        } else {
            if (this.buffer.remainLength > 0) {
                this.sink.write(this.buffer.readToEnd())
            }
            this.sink.flush()
        }
    }

    func getBuffer(): ByteArrayStream {
        return buffer
    }

    public func close(): Unit {
        if (!closed) {
            if (buffer.remainLength > 0) {
                this.sink.write(this.buffer.readToEnd())
            }
            sink.close()
            closed = true
        }
    }
}

class FramingSink <: Sink {
    private static let EMIT_BUFFER_SIZE = 16384
    private let sendBuffer: ByteArrayStream = ByteArrayStream()
    var stream: Option<H2Stream> = Option<H2Stream>.None
    var trailers: Option<Header> = Option<Header>.None
    var closed: Bool = false
    var finished: Bool = false

    public mut prop http2Stream: H2Stream {
        get() {
            return stream.getOrThrow()
        }
        set(value) {
            this.stream = value
        }
    }

    init(outFinished: Bool) {
        this.finished = outFinished
    }

    public func write(bytes: Array<Byte>): Unit {
        sendBuffer.write(bytes)
        while (sendBuffer.remainLength >= EMIT_BUFFER_SIZE) {
            emitFrame(false)
        }
    }

    private func emitFrame(outFinishedOnLastFrame: Bool): Unit {
        let toWrite: Int64
        synchronized(http2Stream.mutex) {
            while (http2Stream.bytesLeftInWriteWindow <= 0 && !finished && !closed && !has(http2Stream.errorCode)) {
                http2Stream.mutex.wait()
            }

            http2Stream.checkOutNotClosed()
            toWrite = min(http2Stream.bytesLeftInWriteWindow, sendBuffer.remainLength)
            http2Stream.bytesLeftInWriteWindow -= toWrite
        }

        let outFinished: Bool = outFinishedOnLastFrame && toWrite == sendBuffer.remainLength
        http2Stream.cc.writeData(http2Stream.id, outFinished, sendBuffer, toWrite)
    }

    public func flush(): Unit {
        synchronized(http2Stream.mutex) {
            http2Stream.checkOutNotClosed()
        }

        while (sendBuffer.remainLength > 0) {
            emitFrame(true)
            http2Stream.cc.flush()
        }
    }

    public func close(): Unit {
        synchronized(http2Stream.mutex) {
            if (closed) {
                return
            }
        }

        if (!finished) {
            let hasData: Bool = sendBuffer.remainLength > 0
            let hasTrailers: Bool = has(trailers)
            if (hasTrailers) {
                while (sendBuffer.remainLength > 0) {
                    emitFrame(false)
                }
                let result: ArrayList<HeaderField> = ArrayList<HeaderField>()
                for ((k, v) in trailers.getOrThrow()) {
                    result.append(HeaderField(k.toLower(), v[0]))
                }
                trailers = Option<Header>.None
                http2Stream.cc.writeHeaders(http2Stream.id, true, result)
            } else if (hasData) {
                while (sendBuffer.remainLength > 0) {
                    emitFrame(true)
                }
            } else {
                http2Stream.cc.writeData(http2Stream.id, true, ByteArrayStream(), 0)
            }
        }

        synchronized(http2Stream.mutex) {
            closed = true
        }

        http2Stream.cc.flush()
        http2Stream.cancelStreamIfNecessary()
    }
}

class BlackHole <: Sink {
    public func write(_: Array<Byte>): Unit {}

    public func flush(): Unit {}

    public func close(): Unit {}
}

open class ForwardingSink <: Sink {
    protected let delegate: Sink

    public init(delegate: Sink) {
        this.delegate = delegate
    }

    public open func write(bytes: Array<Byte>): Unit {
        this.delegate.write(bytes)
    }

    public open func flush(): Unit {
        this.delegate.flush()
    }

    public open func close(): Unit {
        this.delegate.close()
    }
}

class FileSink <: Sink {
    let file: File

    init(file: File) {
        this.file = file
    }

    public func write(bytes: Array<Byte>): Unit {
        file.write(bytes)
    }

    public func flush(): Unit {
        file.flush()
    }

    public func close(): Unit {
        file.close()
    }
}

class FaultHidingSink <: ForwardingSink {
    var hasErrors = false
    let editor: Editor

    init(sink: Sink, editor: Editor) {
        super(sink)
        this.editor = editor
    }

    public override func write(bytes: Array<Byte>): Unit {
        if (hasErrors) {
            return
        }

        try {
            super.write(bytes)
        } catch (e: FSException | EOFException) {
            hasErrors = true
            onException()
        }
    }

    public override func flush(): Unit {
        if (hasErrors) {
            return
        }

        try {
            super.flush()
        } catch (e: FSException | EOFException) {
            hasErrors = true
            onException()
        }
    }

    public override func close(): Unit {
        if (hasErrors) {
            return
        }

        try {
            super.close()
        } catch (e: HttpException | FSException | EOFException) {
            hasErrors = true
            onException()
        }
    }

    func onException() {
        synchronized(editor.diskLruCache.lock) {
            editor.detach()
        }
    }
}
