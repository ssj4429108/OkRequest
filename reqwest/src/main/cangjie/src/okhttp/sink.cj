/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2022-2024. All rights resvered.
 */

/**
 * @file
 * The file declares the Sink impls.
 */

package ohos_app_cangjie_OkRequest.okhttp

import ohos_app_cangjie_OkRequest.okio.*
import ohos.hilog.Hilog

class KnownLengthSink <: Sink {
    private var closed: Bool = false
    private let exchange: Http1ExchangeCodec
    private let timeouts: ForwardingTimeout

    init(exchange: Http1ExchangeCodec) {
        this.exchange = exchange
        this.timeouts = ForwardingTimeout(exchange.sink.timeout())
    }
    public override func timeout(): Timeout {
        return timeouts
    }

    public override func write(source: Buffer, byteCount: Int64) {

        Hilog.info(3, "ok-request", "write2")
        if (closed) {
            throw IllegalStateException("closed")
        }
        if ((0 | byteCount) < 0 || 0 > source.size || (source.size - 0) < byteCount) {
            throw ArrayIndexOutOfBoundsException("length=${source.size}, offset=0, count=${byteCount}")
        }
        exchange.sink.write(source, byteCount)
    }
    public override func flush(): Unit {

        if (closed) {
            return
        }

        Hilog.info(3, "ok-request", "sink: 1")
        exchange.sink.flush()
    }

    public override func close(): Unit {
        if (closed) {
            return
        }
        closed = true
        detachTimeout(timeouts)
        exchange.state = Http1ExchangeCodec.STATE_READ_RESPONSE_HEADERS
    }

    private func detachTimeout(timeout: ForwardingTimeout) {
        let oldDelegate: Timeout = timeout.delegate()
        timeout.setDelegate(Timeout.NONE)
        oldDelegate.clearDeadline()
        oldDelegate.clearTimeout()
    }

    /**
     * The Function is isClosed
     *
     * @return Type of Bool
     * @since 0.32.5
     */
    public override func isClosed(): Bool {
        this.closed
    }

    /**
     * The Function is toString
     *
     * @return Type of String
     * @since 0.32.5
     */
    public override func toString(): String {
        return "KnownLengthSink"
    }
}

class ChunkedSink <: Sink {
    private var closed: Bool = false
    private let exchange: Http1ExchangeCodec
    private let timeouts: ForwardingTimeout

    init(exchange: Http1ExchangeCodec) {
        this.exchange = exchange
        this.timeouts = ForwardingTimeout(exchange.sink.timeout())
    }

    public func timeout(): Timeout {
        return timeouts
    }

    public override func write(source: Buffer, byteCount: Int64): Unit {

        Hilog.info(3, "ok-request", "write3")
        if (closed) {
            throw IllegalStateException("closed")
        }
        if (byteCount == 0) {
            return
        }
        var lengthHex = UInt64ToHexString(UInt64(byteCount))
        this.exchange.sink.write(lengthHex)
        this.exchange.sink.write(CRLF)
        this.exchange.sink.write(source, byteCount)
        this.exchange.sink.write(CRLF)
    }

    public func flush(): Unit {
        if (closed) {
            return
        }


        Hilog.info(3, "ok-request", "sink: 2")
        exchange.sink.flush()
    }

    public func close(): Unit {
        if (closed) {
            return
        }

        closed = true
        this.exchange.sink.write("0\r\n\r\n".toArray())
        detachTimeout(timeouts)
        exchange.state = Http1ExchangeCodec.STATE_READ_RESPONSE_HEADERS
    }
    private func detachTimeout(timeout: ForwardingTimeout) {
        let oldDelegate: Timeout = timeout.delegate()
        timeout.setDelegate(Timeout.NONE)
        oldDelegate.clearDeadline()
        oldDelegate.clearTimeout()
    }

    /**
     * The Function is isClosed
     *
     * @return Type of Bool
     * @since 0.32.5
     */
    public override func isClosed(): Bool {
        this.closed
    }

    /**
     * The Function is toString
     *
     * @return Type of String
     * @since 0.32.5
     */
    public override func toString(): String {
        return "ChunkedSink"
    }
}

class RequestBodySink <: ForwardingSink {
    private var completed: Bool = false
    private var contentLength: Int64
    private var bytesReceived: Int64 = 0
    private var closed: Bool = false
    private let exchange: Exchange
    private let sink: Sink

    init(sink: Sink, contentLength: Int64, exchange: Exchange) {
        super(sink)
        this.sink = sink
        this.contentLength = contentLength
        this.exchange = exchange
    }

    public override func write(source: Buffer, byteCount: Int64) {

        Hilog.info(3, "ok-request", "write4")
        if (closed) {
            throw IllegalStateException("closed")
        }
        if (contentLength != -1 && bytesReceived + byteCount > contentLength) {
            throw ProtocolException("expected ${contentLength} bytes but received ${bytesReceived + byteCount}",)
        }
        try {
            super.write(source, byteCount)
            this.bytesReceived += byteCount
        } catch (e: IOException) {
            complete(HttpException(e.message))
            throw e
        }
    }


    public override func flush(): Unit {


        Hilog.info(3, "ok-request", "sink: 3")
        try {
            sink.flush()
        } catch (e: HttpException) {
            complete(HttpException(e.message))
            throw e
        }
    }
    public override func close(): Unit {
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

    /**
     * The Function is isClosed
     *
     * @return Type of Bool
     * @since 0.32.5
     */
    public override func isClosed(): Bool {
        this.closed
    }
}


public class RealBufferSink <: BufferedSink {
    var closed: Bool = false
    public let sink: Sink
//    private var buffer: ByteArrayStream = ByteArrayStream()

    private let bufferField = Buffer()

    public init(sink: Sink) {
        this.sink = sink
    }

    public override func buffer() {
        return bufferField
    }

    public override func write(byteString: ByteString): BufferedSink {
        return commonWrite(byteString)    
    }

    public override func write(source: Array<Byte>): BufferedSink {
        return commonWrite(source)
    }

    public override func write(source: Array<Byte>, offset: Int64, byteCount: Int64): BufferedSink {
        return commonWrite(source, offset, byteCount)
    }

    public override func write(source: Source, byteCount: Int64): BufferedSink {
        return commonWrite(source, byteCount)
    }

    public override func write(source: Buffer, byteCount: Int64): Unit {

        Hilog.info(3, "ok-request", "write5")
        commonWrite(source, byteCount)
    }

    public override func writeAll(source: Source): Int64 {
        return commonWriteAll(source)
    }
    
    public override func writeUtf8(string: String): BufferedSink {
        return commonWriteUtf8(string)
    }
    /*
     * The Function is writeUtf8
     *
     * @param string of String
     * @param beginIndex of Int64
     * @param endIndex of Int64
     *
     * @return Type of BufferedSink
     * @since 0.32.5
     */
    public override func writeUtf8(string: String, beginIndex: Int64, endIndex: Int64): BufferedSink {
        return commonWriteUtf8(string, beginIndex, endIndex)
    }
    /*
     * The Function is writeUtf8CodePoint
     *
     * @param codePoInt64 of Int64
     *
     * @return Type of BufferedSink
     * @since 0.32.5
     */
    public override func writeUtf8CodePoint(codePoInt64: Int64): BufferedSink {
        return commonWriteUtf8CodePoint(codePoInt64)
    }
    // func writeString(string: String, charset: Charset): BufferedSink {
    //     return 
    // }
    // func writeString(string: String, beginIndex: Int64, endIndex: Int64, charset: Charset): BufferedSink
    /*
     * The Function is writeInt8
     *
     * @param value of Int64
     *
     * @return Type of BufferedSink
     * @since 0.32.5
     */
    public override func writeInt8(value: Int64): BufferedSink {
        return commonWriteByte(value)
    }
    /*
     * The Function is writeInt16
     *
     * @param value of Int64
     *
     * @return Type of BufferedSink
     * @since 0.32.5
     */
    public override func writeInt16(value: Int64): BufferedSink {
        return commonWriteShort(value)
    }
    /*
     * The Function is writeInt16Le
     *
     * @param value of Int64
     *
     * @return Type of BufferedSink
     * @since 0.32.5
     */
    public override func writeInt16Le(value: Int64): BufferedSink {
        return commonWriteShortLe(value)
    }
    /*
     * The Function is writeInt32
     *
     * @param value of Int64
     *
     * @return Type of BufferedSink
     * @since 0.32.5
     */
    public override func writeInt32(value: Int64): BufferedSink {
        return commonWriteInt(value)
    }
    /*
     * The Function is writeInt32Le
     *
     * @param value of Int64
     *
     * @return Type of BufferedSink
     * @since 0.32.5
     */
    public override func writeInt32Le(value: Int64): BufferedSink {
        return commonWriteIntLe(value)
    }
    /*
     * The Function is writeInt64
     *
     * @param value of Int64
     *
     * @return Type of BufferedSink
     * @since 0.32.5
     */
    public override func writeInt64(value: Int64): BufferedSink {
        return commonWriteLong(value)
    }
    /*
     * The Function is writeInt64Le
     *
     * @param value of Int64
     *
     * @return Type of BufferedSink
     * @since 0.32.5
     */
    public override func writeInt64Le(value: Int64): BufferedSink {
        return commonWriteLongLe(value)
    }

    public override func emitCompleteSegments(): BufferedSink {
        return commonEmitCompleteSegments()
    }

    public override func emit(): BufferedSink {
        return commonEmit()
    }

    public override func flush() {


        Hilog.info(3, "ok-request", "sink: 4")
        return commonFlush()
    }
    
    public override func close(): Unit {
        return commonClose()
    }

    public override func isClosed(): Bool {
        return closed
    }

    public override func toString(): String {
        return commonToString()
    }

    public override func timeout(): Timeout {
        return commonTimeout()
    }


//    public func write(bytes: Array<Byte>): Unit {
//        if (closed) {
//            throw IllegalStateException("closed")
//        } else {
//            buffer.write(bytes)
//        }
//    }
//
//    public func flush(): Unit {
//        if (closed) {
//            throw IllegalStateException("closed")
//        } else {
//            if (this.buffer.remainLength > 0) {
//                this.sink.write(this.buffer.readToEnd())
//            }
//            this.sink.flush()
//        }
//    }
//
//    func getBuffer(): ByteArrayStream {
//        return buffer
//    }
//
//    public func close(): Unit {
//        if (!closed) {
//            if (buffer.remainLength > 0) {
//                this.sink.write(this.buffer.readToEnd())
//            }
//            sink.close()
//            closed = true
//        }
//    }

    func commonWrite(source: Buffer, byteCount: Int64) {
        if (closed) {
            throw IllegalStateException("closed")
        }
        buffer().write(source, byteCount)
        emitCompleteSegments()
    }

    func commonWrite(byteString: ByteString): BufferedSink {
        if (closed) {
            throw IllegalStateException("closed")
        }
        buffer().write(byteString)
        return emitCompleteSegments()
    }

//    func commonWrite(byteString: ByteString, offset: Int32, byteCount: Int32): BufferedSink {
//        if (closed) {
//            throw IllegalStateException("closed")
//        }
//        buffer().write(byteString, offset, byteCount)
//        return emitCompleteSegments()
//    }

    func commonWriteUtf8(string: String): BufferedSink {
        if (closed) {
            throw IllegalStateException("closed")
        }
        buffer().writeUtf8(string)
        return emitCompleteSegments()
    }

    func commonWriteUtf8(string: String, beginIndex: Int64, endIndex: Int64): BufferedSink {
        if (closed) {
            throw IllegalStateException("closed")
        }
        buffer().writeUtf8(string, beginIndex, endIndex)
        return emitCompleteSegments()
    }

    func commonWriteUtf8CodePoint(codePoint: Int64): BufferedSink {
        if (closed) {
            throw IllegalStateException("closed")
        }
        buffer().writeUtf8CodePoint(codePoint)
        return emitCompleteSegments()
    }

    func commonWrite(source: Array<Byte>): BufferedSink {
        if (closed) {
            throw IllegalStateException("closed")
        }
        buffer().write(source)
        return emitCompleteSegments()
    }

    func commonWrite(source: Array<Byte>, offset: Int64, byteCount: Int64): BufferedSink {
        if (closed) {
            throw IllegalStateException("closed")
        }
        buffer().write(source, offset, byteCount)
        return emitCompleteSegments()
    }

    func commonWriteAll(source: Source): Int64 {
        var totalBytesRead = 0
        while (true) {
            let readCount: Int64 = source.read(buffer(), Segment.SIZE)
            if (readCount == -1) {
                break
            }
            totalBytesRead += readCount
            emitCompleteSegments()
        }
        return totalBytesRead
    }

    func commonWrite(source: Source, byteCount: Int64): BufferedSink {
        var remainingByteCount = byteCount
        while (remainingByteCount > 0) {
            let read = source.read(buffer(), remainingByteCount)
            if (read == -1) {
                throw EOFException()
            }
            remainingByteCount -= read
            emitCompleteSegments()
        }
        return this
    }

    func commonWriteByte(b: Int64): BufferedSink {
        if (closed) {
            throw IllegalStateException("closed")
        }
        buffer().writeInt8(b)
        return emitCompleteSegments()
    }

    func commonWriteShort(s: Int64): BufferedSink {
        if (closed) {
            throw IllegalStateException("closed")
        }
        buffer().writeInt16(s)
        return emitCompleteSegments()
    }

    func commonWriteShortLe(s: Int64): BufferedSink {
        if (closed) {
            throw IllegalStateException("closed")
        }
        buffer().writeInt16Le(s)
        return emitCompleteSegments()
    }

    func commonWriteInt(i: Int64): BufferedSink {
        if (closed) {
            throw IllegalStateException("closed")
        }
        buffer().writeInt32(i)
        return emitCompleteSegments()
    }

    func commonWriteIntLe(i: Int64): BufferedSink {
        if (closed) {
            throw IllegalStateException("closed")
        }
        buffer().writeInt32Le(i)
        return emitCompleteSegments()
    }

    func commonWriteLong(v: Int64): BufferedSink {
        if (closed) {
            throw IllegalStateException("closed")
        }
        buffer().writeInt64(v)
        return emitCompleteSegments()
    }

    func commonWriteLongLe(v: Int64): BufferedSink {
        if (closed) {
            throw IllegalStateException("closed")
        }
        buffer().writeInt64Le(v)
        return emitCompleteSegments()
    }

//    func commonWriteDecimalLong(v: Int64): BufferedSink {
//        if (closed) {
//            throw IllegalStateException("closed")
//        }
//        buffer().writeDecimalLong(v)
//        return emitCompleteSegments()
//    }

//    func commonWriteHexadecimalUnsignedLong(v: Int64): BufferedSink {
//        if (closed) {
//            throw IllegalStateException("closed")
//        }
//        buffer().writeHexadecimalUnsignedLong(v)
//        return emitCompleteSegments()
//    }

    func commonEmitCompleteSegments(): BufferedSink {
        if (closed) {
            throw IllegalStateException("closed")
        }
        let byteCount = buffer().completeSegmentByteCount()
        if (byteCount > 0) {
            this.sink.write(buffer(), byteCount)
        }
        return this
    }

    func commonEmit(): BufferedSink {
        if (closed) {
            throw IllegalStateException("closed")
        }
        let byteCount = buffer().size
        if (byteCount > 0) {
            this.sink.write(buffer(), byteCount)
        }
        return this
    }

    func commonFlush() {
        if (closed) {
            throw IllegalStateException("closed")
        }
        if (buffer().size > 0) {
            this.sink.write(buffer(), buffer().size)
        }
        sink.flush()
    }

    func commonClose(): Unit {
        if (closed) {
            return
        }

        var thrown: Option<Exception> = Option<Exception>.None
        try {
            if (buffer().size > 0) {
                this.sink.write(buffer(), buffer().size)
            }
        } catch (e: Exception) {
            thrown = e
        }

        try {
            this.sink.close()
        } catch (e: Exception) {
            
            match(thrown) {
                case Some(e) => ()
                case None => thrown = Some(e)
            }
        }
        closed = true
        match(thrown) {
            case Some(e) => throw e
            case None => ()
        }
    }

    func commonTimeout(): Timeout {
        return this.sink.timeout()
    }

    func commonToString(): String {
        return "buffer(${sink})"
    }
}


class FramingSink <: Sink {
    private static let EMIT_BUFFER_SIZE = 16384
    private let sendBuffer = Buffer()
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
    public func write(source: Buffer, byteCount: Int64): Unit {

        Hilog.info(3, "ok-request", "write6")
        sendBuffer.write(source.readByteArray(byteCount))
        while(sendBuffer.size >= EMIT_BUFFER_SIZE) {
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
            toWrite = min(http2Stream.bytesLeftInWriteWindow, sendBuffer.size)
            http2Stream.bytesLeftInWriteWindow -= toWrite
        }

        let outFinished: Bool = outFinishedOnLastFrame && toWrite == sendBuffer.size
        http2Stream.cc.writeData(http2Stream.id, outFinished, sendBuffer, toWrite)
    }

    public override func flush(): Unit {
        Hilog.info(3, "ok-request", "sink: 5")
        synchronized(http2Stream.mutex) {
            http2Stream.checkOutNotClosed()
        }

        while (sendBuffer.size > 0) {
            emitFrame(true)
            http2Stream.cc.flush()
        }
    }

    public override func close(): Unit {
        synchronized(http2Stream.mutex) {
            if (closed) {
                return
            }
        }

        if (!finished) {
            let hasData: Bool = sendBuffer.size > 0
            let hasTrailers: Bool = has(trailers)
            if (hasTrailers) {
                while (sendBuffer.size > 0) {
                    emitFrame(false)
                }
                let result: ArrayList<HeaderField> = ArrayList<HeaderField>()
                for ((k, v) in trailers.getOrThrow()) {
                    result.append(HeaderField(k.toLower(), v[0]))
                }
                trailers = Option<Header>.None
                http2Stream.cc.writeHeaders(http2Stream.id, true, result)
            } else if (hasData) {
                while (sendBuffer.size > 0) {
                    emitFrame(true)
                }
            } else {
                http2Stream.cc.writeData(http2Stream.id, true, Buffer(), 0)
            }
        }

        synchronized(http2Stream.mutex) {
            closed = true
        }

        http2Stream.cc.flush()
        http2Stream.cancelStreamIfNecessary()
    }
    
    public override func isClosed(): Bool {
        return closed
    }

    public override func toString(): String {
        return "FramingSink"
    }

    public override func timeout(): Timeout {
        return Timeout.NONE
    }
}

class BlackHole <: Sink {
    public func write(_: Buffer, _: Int64): Unit {}

    public func flush(): Unit {}

    public func close(): Unit {}

    public func timeout() {
        return Timeout.NONE
    }

    public override func isClosed(): Bool {
        return true
    }

    public override func toString(): String {
        return "BlackHole"
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

    public func write(source: Buffer, byteCount: Int64) {
        Hilog.info(3, "ok-request", "write7")
        file.write(source.readByteArray(byteCount))   
    }
 
    public func flush(): Unit {

        Hilog.info(3, "ok-request", "sink: 6")
        file.flush()
    }

    public func close(): Unit {
        file.close()
    }

    public override func isClosed(): Bool {
        return file.isClosed()
    }
    
    public func timeout(): Timeout {
        return Timeout.NONE
    }

    public func toString(): String {
        return "FileSink"
    }
}

class FaultHidingSink <: ForwardingSink {
    var hasErrors = false
    let editor: Editor

    init(sink: Sink, editor: Editor) {
        super(sink)
        this.editor = editor
    }

    public override func write(source: Buffer, byteCount: Int64): Unit {

        Hilog.info(3, "ok-request", "write8")
        if (hasErrors) {
            return
        }

        try {
            super.write(source, byteCount)
        } catch (e: FSException | EOFException) {
            hasErrors = true
            onException()
        }
    }

    public override func flush(): Unit {
        Hilog.info(3, "ok-request", "flush1118")
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
