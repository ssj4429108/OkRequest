/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2022-2024. All rights resvered.
 */

/**
 * @file
 * The file declars the RealBufferedSink class.
 */
package ohos_app_cangjie_OkRequest.okio
import ohos.hilog.Hilog


class RealBufferedSink <: BufferedSink {

    /**
     * let member buf type is okio.Buffer
     * @since 0.32.5
     */
    public let buf: Buffer = Buffer()

    /**
     * let member sink type is Sink
     * @since 0.32.5
     */
    public let sink: Sink

    var closed: Bool = false

    init (sink: Sink){
        this.sink = sink
    }

    /**
     * The Function is buffer
     *
     * @return Type of Buffer
     * @since 0.32.5
     */
    public override func buffer (): Buffer {
        return this.buf
    }

    /**
     * The Function is write
     *
     * @param byteString of ByteString
     *
     * @return Type of BufferedSink
     * @since 0.32.5
     */
    public override func write(byteString: ByteString): BufferedSink {
        if (this.closed) {
            throw IllegalArgumentException("closed.")
        }
        this.buf.write(byteString)
        return emitCompleteSegments()
    }

    /**
     * The Function is write
     *
     * @param source of Array<Byte>
     *
     * @return Type of BufferedSink
     * @since 0.32.5
     */
    public override func write(source: Array<Byte>): BufferedSink {
        if (closed) {
            throw IllegalStateException("closed")
        }
        this.buf.write(source)
        return emitCompleteSegments()
    }

    /**
     * The Function is write
     *
     * @param source of Array<Byte>
     * @param offset of Int64
     * @param byteCount of Int64
     *
     * @return Type of BufferedSink
     * @since 0.32.5
     */
    public override func write(source: Array<Byte>, offset: Int64, byteCount: Int64): BufferedSink {
        if (closed) {
            throw IllegalStateException("closed")
        }
        this.buf.write(source, offset, byteCount)
        return emitCompleteSegments()
    }

    /**
     * The Function is write
     *
     * @param source of Source
     * @param byteCount of Int64
     *
     * @return Type of BufferedSink
     * @since 0.32.5
     */
    public override func write(source: Source, bytecount: Int64): BufferedSink {
        var byteCount = bytecount
        while (byteCount > 0) {
            let read = source.read(this.buf, byteCount)
            if (read == -1) {
                throw EOFException()
            }
            byteCount -= read
            emitCompleteSegments()
        }
        return this
    }

    /**
     * The Function is writeAll
     *
     * @param source of Source
     *
     * @return Type of Int64
     * @since 0.32.5
     */
    public override func writeAll(source: Source): Int64 {
        var totalBytesRead = 0
        var readCount = source.read(this.buf, Segment.SIZE)
        while (readCount != -1) {
            totalBytesRead += readCount
            emitCompleteSegments()
            readCount = source.read(this.buf, Segment.SIZE)
        }
        return totalBytesRead
    }
    /**
     * The Function is writeUtf8
     *
     * @param string of String
     *
     * @return Type of BufferedSink
     * @since 0.32.5
     */
    public override func writeUtf8(string: String): BufferedSink {
        this.buf.writeUtf8(string)
        return emitCompleteSegments()
    }

    /**
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
        this.buf.writeUtf8(string, beginIndex, endIndex)
        return emitCompleteSegments()
    }

    /**
     * The Function is writeUtf8CodePoint
     *
     * @param codePoInt64 of Int64
     *
     * @return Type of BufferedSink
     * @since 0.32.5
     */
    public override func writeUtf8CodePoint(codePoInt64: Int64): BufferedSink {
        this.buf.writeUtf8CodePoint(codePoInt64)
        return emitCompleteSegments()
    }

    /**
     * The Function is writeInt8
     *
     * @param value of Int64
     *
     * @return Type of BufferedSink
     * @since 0.32.5
     */
    public override func writeInt8(value: Int64): BufferedSink {
        this.buf.writeInt8(value)
        return emitCompleteSegments()
    }

    /**
     * The Function is writeInt16
     *
     * @param value of Int64
     *
     * @return Type of BufferedSink
     * @since 0.32.5
     */
    public override func writeInt16(value: Int64): BufferedSink {
        this.buf.writeInt16(value)
        return emitCompleteSegments()
    }

    /**
     * The Function is writeInt16Le
     *
     * @param value of Int64
     *
     * @return Type of BufferedSink
     * @since 0.32.5
     */
    public override func writeInt16Le(value: Int64): BufferedSink {
        this.buf.writeInt16Le(value)
        return emitCompleteSegments()
    }

    /**
     * The Function is writeInt32
     *
     * @param value of Int64
     *
     * @return Type of BufferedSink
     * @since 0.32.5
     */
    public override func writeInt32(value: Int64): BufferedSink {
        this.buf.writeInt32(value)
        return emitCompleteSegments()
    }

    /**
     * The Function is writeInt32Le
     *
     * @param value of Int64
     *
     * @return Type of BufferedSink
     * @since 0.32.5
     */
    public override func writeInt32Le(value: Int64): BufferedSink {
        this.buf.writeInt32Le(value)
        return emitCompleteSegments()
    }

    /**
     * The Function is writeInt64
     *
     * @param value of Int64
     *
     * @return Type of BufferedSink
     * @since 0.32.5
     */
    public override func writeInt64(value: Int64): BufferedSink {
        this.buf.writeInt64(value)
        return emitCompleteSegments()
    }

    /**
     * The Function is writeInt64Le
     *
     * @param value of Int64
     *
     * @return Type of BufferedSink
     * @since 0.32.5
     */
    public override func writeInt64Le(value: Int64): BufferedSink {
        this.buf.writeInt64Le(value)
        return emitCompleteSegments()
    }

    /**
     * The Function is flush
     *
     * @return Type of Unit
     * @since 0.32.5
     */
    public override func flush(): Unit {
        if (this.closed) {
            throw IllegalArgumentException("closed")
        }
        if (this.buf.size > 0) {
            this.sink.write(this.buf, this.buf.size)
        }
        sink.flush()
    }

    /**
     * The Function is emit
     *
     * @return Type of BufferedSink
     * @since 0.32.5
     */
    public override func emit(): BufferedSink {
        if (closed) {
            throw IllegalStateException("closed")
        }
        let byteCount = this.buf.size
        if (byteCount > 0) {
            this.sink.write(this.buf, byteCount)
        }
        return this
    }

    /**
     * The Function is close
     *
     * @return Type of Unit
     * @since 0.32.5
     */
    public override func close(): Unit {
        if (this.closed) {
            return
        }
        var thrown: ?Exception = None
        try {
            if (this.buf.size >0) {
                this.sink.write(this.buf, this.buf.size)
            }
        } catch (e:Exception) {
            thrown = e
        }
        try {
            this.sink.close()
        } catch (e: Exception){
            match (thrown) {
                case None => thrown = e
                case Some(v) => () 
            }
        }
        this.closed = true
        match (thrown) {
            case None => ()
            case Some(v) => throw v
        }
    } 

    /**
     * The Function is timeout
     *
     * @return Type of Timeout
     * @since 0.32.5
     */
    public override func timeout(): Timeout {
        return this.sink.timeout()
    }

    /**
     * The Function is write
     *
     * @param source of Buffer
     * @param byteCount of Int64
     *
     * @return Type of Unit
     * @since 0.32.5
     */
    public override func write(source: Buffer, byteCount: Int64): Unit {
        Hilog.info(3, "ok-request", "write9")
        this.buf.write(source, byteCount)
        emitCompleteSegments()
    }

    /**
     * The Function is isClosed
     *
     * @return Type of Bool
     * @since 0.32.5
     */
    public override func isClosed():Bool {
        this.closed
    }

    /**
     * The Function is emitCompleteSegments
     *
     * @return Type of BufferedSink
     * @since 0.32.5
     */
    public override func emitCompleteSegments(): BufferedSink {
        if (this.closed) {
            throw IllegalArgumentException("closed.")
        }
        var byteCount = this.buf.completeSegmentByteCount()
        if (byteCount > 0) {
            this.sink.write(this.buf, byteCount)
        }
        return this
    }

    /**
     * The Function is toString
     *
     * @return Type of String
     * @since 0.32.5
     */
    public override func toString (): String {
        return "RealBufferedSink: ${this.buf.toString()}"
    }
}


