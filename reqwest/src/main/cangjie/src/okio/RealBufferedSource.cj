/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2022-2024. All rights resvered.
 */

/**
 * @file
 * The file declars the RealBufferedSource class.
 */
package ohos_app_cangjie_OkRequest.okio
import ohos.hilog.Hilog


class RealBufferedSource <: BufferedSource {

    /**
     * let member buf type is Buffer
     * @since 0.32.5
     */
    public let buf: Buffer = Buffer()

    /**
     * let member source type is Source
     * @since 0.32.5
     */
    public let source: Source
    
    var closed: Bool = false

    /**
     * The Function is init constructor
     *
     * @param source of Source
     * @since 0.32.5
     */
    public init (source: Source){
        this.source = source
    }

    /**
     * The Function is getBuffer
     *
     * @return Type of Buffer
     * @since 0.32.5
     */
    public override func getBuffer (): Buffer {
        return this.buf
    }

    /**
     * The Function is read
     *
     * @param sink of Buffer
     * @param byteCount of Int64
     *
     * @return Type of Int64
     * @since 0.32.5
     */
    public override func read (sink: Buffer, byteCount: Int64): Int64 {
        if (byteCount <0) {
            throw IllegalArgumentException("byteCount <0: ${byteCount}")
        }
        if (closed) {
            throw IllegalArgumentException("closed")
        }
        if (this.buf.size == 0) {
            let read = this.source.read(this.buf, Segment.SIZE)
            if (read == -1) {
                return -1
            }
        }
        let toRead = min(byteCount, this.buf.size)
        return this.buf.read(sink, toRead)
    }

    /**
     * The Function is exhausted
     *
     * @return Type of Bool
     * @since 0.32.5
     */
    public override func exhausted (): Bool {
        if (closed) {
            throw IllegalArgumentException("closed")
        }
        return this.buf.exhausted() && this.source.read(this.buf, Segment.SIZE) == -1
    }

    /**
     * The Function is require
     *
     * @param byteCount of Int64
     *
     * @return Type of Unit
     * @since 0.32.5
     */
    public override func require(byteCount: Int64): Unit {
        if (!request(byteCount)) {
            throw EOFException()
        }
    }

    /**
     * The Function is request
     *
     * @param byteCount of Int64
     *
     * @return Type of Bool
     * @since 0.32.5
     */
    public override func request (byteCount: Int64): Bool {
        if (byteCount <0) {
            throw IllegalArgumentException("byteCount <0: ${byteCount}")
        }
        if (closed) {
            throw IllegalArgumentException("closed")
        }
        while (this.buf.size < byteCount) {
            if (source.read(this.buf, Segment.SIZE) == -1){
                return false
            }
        }
        return true
    }
    
    /**
     * The Function is readInt8
     *
     * @return Type of Int8
     * @since 0.32.5
     */
    public override func readInt8(): Int8 {
        this.require(1)
        return buf.readInt8()
    }

    /**
     * The Function is readByteString
     *
     * @return Type of ByteString
     * @since 0.32.5
     */
    public override func readByteString (): ByteString {
        buf.writeAll(source)
        return buf.readByteString()
    }

    /**
     * The Function is readByteString
     *
     * @param byteCount of Int64
     *
     * @return Type of ByteString
     * @since 0.32.5
     */
    public override func readByteString (byteCount: Int64): ByteString {
        require(byteCount)
        return buf.readByteString()
    }

    // public func select (options: Options): Int32 {
    //     return 0
    // }

    /**
     * The Function is readByteArray
     *
     * @return Type of Array<Byte>
     * @since 0.32.5
     */
    public override func readByteArray (): Array<Byte> {
        buf.writeAll(source)
        return buf.readByteArray()
    }

    /**
     * The Function is readByteArray
     *
     * @param byteCount of Int64
     *
     * @return Type of Array<Byte>
     * @since 0.32.5
     */
    public override func readByteArray (byteCount: Int64): Array<Byte> {
        require(byteCount)
        return buf.readByteArray(byteCount)
    }

    /**
     * The Function is read
     *
     * @param sink of Array<Byte>
     *
     * @return Type of Int64
     * @since 0.32.5
     */
    public override func read(sink: Array<Byte>): Int64 {
        return read(sink, 0, sink.size)
    }

    /**
     * The Function is readFully
     *
     * @param sink of Array<Byte>
     *
     * @return Type of Unit
     * @since 0.32.5
     */
    public override func readFully(sink: Array<Byte>): Unit {
        try {
            this.require(sink.size)
        } catch (e: EOFException) {
            var offset = 0
            while (this.buf.size > 0) {
                let read = this.buf.read(sink, offset, this.buf.size)
                if (read == -1) {
                    throw Exception()
                }
                offset += read
            }
            throw e
        }
        this.buf.readFully(sink)
    }

    /**
     * The Function is read
     *
     * @param sink of Array<Byte>
     * @param offset of Int64
     * @param byteCount of Int64
     *
     * @return Type of Int64
     * @since 0.32.5
     */
    public override func read(sink: Array<Byte>, offset: Int64, byteCount: Int64): Int64 {
        Util.checkOffsetAndCount(sink.size, offset, byteCount);
        if (this.buf.size == 0) {
            let read = source.read(this.buf, Segment.SIZE);
            if (read == -1) {
                return -1
            }
        }
        let toRead = min(byteCount, this.buf.size);
        return this.buf.read(sink, offset, toRead);
    }

    /**
     * The Function is read
     *
     * @param sink of ByteBuffer
     *
     * @return Type of Int64
     * @since 0.32.5
     */
    public override func read (sink: ByteBuffer): Int64 {
        if (this.buf.size == 0) {
            let read = source.read(this.buf, Segment.SIZE)
            if (read == -1) {
                return -1
            }
        }
        return this.buf.read(sink)
    }

    /**
     * The Function is readFully
     *
     * @param sink of Buffer
     * @param byteCount of Int64
     *
     * @return Type of Unit
     * @since 0.32.5
     */
    public override func readFully (sink: Buffer, byteCount: Int64): Unit {
        try {
            require(byteCount)
        } catch ( e: EOFException) {
            sink.writeAll(this.buf)
            throw e
        }
        this.buf.readFully(sink, byteCount)
    }

    /**
     * The Function is readAll
     *
     * @param sink of Sink
     *
     * @return Type of Int64
     * @since 0.32.5
     */
    public override func readAll(sink: Sink): Int64 {
        var totalBytesWritten = 0
        while (this.source.read(this.buf, Segment.SIZE) != -1) {
            let emitByteCount = this.buf.completeSegmentByteCount()
            if (emitByteCount > 0) {
                totalBytesWritten += emitByteCount
                sink.write(this.buf, emitByteCount)
            }
        }
        if (this.buf.size > 0) {
            totalBytesWritten += this.buf.size
            sink.write(this.buf, this.buf.size)
        }
        return totalBytesWritten
    }

    /**
     * The Function is readUtf8
     *
     * @return Type of ?String
     * @since 0.32.5
     */
    public override func readUtf8 (): String {
        this.buf.writeAll(source)
        return this.buf.readUtf8()
    }

    /**
     * The Function is readUtf8
     *
     * @param byteCount of Int64
     *
     * @return Type of ?String
     * @since 0.32.5
     */
    public override func readUtf8 (byteCount: Int64): String {
        require(byteCount)
        return this.buf.readUtf8(byteCount)
    }

    /**
     * The Function is readString
     *
     * @return Type of ?String
     * @since 0.32.5
     */
    public override func readString (): String {
        this.buf.writeAll(source)
        return this.buf.readString()
    }

    /**
     * The Function is readString
     *
     * @param byteCount of Int64
     *
     * @return Type of ?String
     * @since 0.32.5
     */
    public override func readString(byteCount: Int64): String {
        require(byteCount)
        return this.buf.readString(byteCount)
    }

    /**
     * The Function is readUtf8Line
     *
     * @return Type of ?String
     * @since 0.32.5
     */
    @OverflowWrapping
    public override func readUtf8Line (): ?String {
        let newline = indexOf(Int8(UInt32(r'\n')))
        if (newline == -1) {
            return if (this.buf.size != 0 ) {
                return readUtf8(this.buf.size)
            } else {
                return None
            }
        }
        return this.buf.readUtf8Line(newline)
    }

    /**
     * The Function is readUtf8LineStrict
     *
     * @return Type of ?String
     * @since 0.32.5
     */
    public override func readUtf8LineStrict (): ?String {
        return readUtf8LineStrict(Int64.Max)
    }

    /**
     * The Function is readUtf8LineStrict
     *
     * @param limit of Int64
     *
     * @return Type of ?String
     * @since 0.32.5
     */
    public override func readUtf8LineStrict (limit: Int64): ?String {
        if (limit < 0) {
            throw IllegalArgumentException("limit < 0: ${limit}")
        }
        let scanLength = if (limit == Int64.Max) {
            Int64.Max
        } else {
            limit + 1
        }
        let newLine = indexOf(let_LF, 0, scanLength)

        if (newLine != -1) {
            return this.buf.readUtf8Line(newLine)
        }
        if(scanLength < Int64.Max) {
            if(request(scanLength)) {
                if (request(scanLength + 1)) {
                    if (this.buf.getInt8(scanLength - 1) == let_CR) {
                        if (this.buf.getInt8(scanLength) == let_LF) {
                            return this.buf.readUtf8Line(scanLength)
                        }

                    }
                }
            }
        }

        let data = Buffer()
        this.buf.copyTo(data, 0, min(32, this.buf.size))
        throw EOFException("\\n not found: limit= ${min(this.buf.size, limit)} content= ${data.readByteString().hex()} …")
    }

    /**
     * The Function is readUtf8CodePoint
     * If the first byte starts with 0, it must be a single byte encoding (that is, a single single byte symbol);
     * If the first byte starts with 110, it must be a double byte encoding (that is, a double symbol sequence consisting of two single byte symbols);
     * If the first byte starts with 1110, it must be a three byte code (that is, a three byte code sequence consisting of three single byte code elements);
     * If the first byte starts with 1111, it must be a four byte code (that is, a three byte code sequence consisting of three single byte code elements);
     * @return Type of Int64
     * @since 0.32.5
     */
    public override func readUtf8CodePoint(): Int64 {
        require(1)
        let b0: Int8 = this.buf.getInt8(0)
        if ((UInt8(b0) & 0xe0) == 0xc0) {
            require(2)
        } else if ((UInt8(b0) & 0xf0) == 0xe0) {
            require(3)
        } else if ((UInt8(b0) & 0xf8) == 0xf0) {
            require(4)
        }
        return this.buf.readUtf8CodePoint()
    }

    /**
     * The Function is readInt16
     *
     * @return Type of Int16
     * @since 0.32.5
     */
    public override func readInt16 (): Int16 {
        require(2)
        return this.buf.readInt16()
    }

    /**
     * The Function is readInt16Le
     *
     * @return Type of Int16
     * @since 0.32.5
     */
    public override func readInt16Le (): Int16 {
        require(2)
        return this.buf.readInt16Le()
    }

    /**
     * The Function is readInt32
     *
     * @return Type of Int32
     * @since 0.32.5
     */
    public override func readInt32 (): Int32 {
        require(4)
        return this.buf.readInt32()
    }

    /**
     * The Function is readInt32Le
     *
     * @return Type of Int32
     * @since 0.32.5
     */
    public override func readInt32Le (): Int32 {
        require(4)
        return this.buf.readInt32Le()
    }

    /**
     * The Function is readInt64
     *
     * @return Type of Int64
     * @since 0.32.5
     */
    public override func readInt64 (): Int64 {
        require(8)
        return this.buf.readInt64()
    }

    /**
     * The Function is readInt64Le
     *
     * @return Type of Int64
     * @since 0.32.5
     */
    public override func readInt64Le (): Int64 {
        require(8)
        return this.buf.readInt64Le()
    }

    /**
     * The Function is readDecimalInt64
     *
     * @return Type of Int64
     * @since 0.32.5
     */
    public override func readDecimalInt64(): Int64 {
        require(1)
        var pos = 0
        while (request(pos + 1)) {
            let b = UInt8(this.buf.getInt8(pos))
            if ((b < let_0 || b > let_9) && (pos != 0 || b != let__)) {
                if (pos == 0) {
                    throw NumberFormatException("")
                }
                break
            }
            pos ++
        }
        return this.buf.readDecimalInt64()
    }
    /**
     * The Function is readHexadecimalUInt64
     *
     * @return Type of Int64
     * @since 0.32.5
     */
    public override func readHexadecimalUInt64(): Int64 {
        require(1)
        var pos = 0
        while (request(pos + 1)) {
            let b = UInt8(this.buf.getInt8(pos))
            if ((b < let_0 || b > let_9) && (b < let_a || b > let_f) && (b < let_A || b > let_F)) {
                if (pos == 0) {
                    throw NumberFormatException("")
                }
                break
            }
            pos ++
        }
        return this.buf.readHexadecimalUInt64()
    }

    /**
     * The Function is skip
     *
     * @param byteCount of Int64
     *
     * @return Type of Unit
     * @since 0.32.5
     */
    public override func skip (bytecount: Int64): Unit {
        if (closed) {
            throw IllegalStateException("closed")
        }
        var byteCount = bytecount
        while (byteCount > 0) {
            if (this.buf.size == 0 && source.read(this.buf, Segment.SIZE) == -1) {
                throw EOFException()
            }
            let toSkip = min(byteCount, this.buf.size);
            this.buf.skip(toSkip);
            byteCount -= toSkip;
        }
    }

    /**
     * The Function is indexOf
     *
     * @param b of Int8
     *
     * @return Type of Int64
     * @since 0.32.5
     */
    public override func indexOf (b: Int8): Int64 {
        return indexOf(b, 0, Int64.Max)
    }

    /**
     * The Function is indexOf
     *
     * @param b of Int8
     * @param fromIndex of Int64
     *
     * @return Type of Int64
     * @since 0.32.5
     */
    public override func indexOf (b: Int8, fromIndex: Int64): Int64 {
        return indexOf(b, fromIndex, Int64.Max)
    }

    /**
     * The Function is indexOf
     *
     * @param b of Int8
     * @param fromIndex of Int64
     * @param toIndex of Int64
     *
     * @return Type of Int64
     * @since 0.32.5
     */
    public override func indexOf (b: Int8, fromindex: Int64, toIndex: Int64): Int64 {
        var fromIndex = fromindex
        if (closed) {
            throw IllegalStateException("closed")
        }
        if (fromIndex < 0 || toIndex < fromIndex) {
            throw  IllegalArgumentException("fromIndex=${fromIndex} toIndex=${toIndex}")
        }
        while (fromIndex < toIndex) {
            let result = this.buf.indexOf(b, fromIndex, toIndex)

            if (result != -1) {
                return result
            }
            let lastBufferSize = this.buf.size
            if (lastBufferSize >= toIndex || source.read(this.buf, Segment.SIZE) == -1){
                return -1
            }
            fromIndex = max(fromIndex, lastBufferSize)
        }
        return -1
    }

    /**
     * The Function is indexOf
     *
     * @param bytes of ByteString
     *
     * @return Type of Int64
     * @since 0.32.5
     */
    public override func indexOf (bytes: ByteString): Int64 {
        return indexOf(bytes, 0)
    }

    /**
     * The Function is indexOf
     *
     * @param bytes of ByteString
     * @param fromIndex of Int64
     *
     * @return Type of Int64
     * @since 0.32.5
     */
    public override func indexOf (bytes: ByteString, fromindex: Int64): Int64 {
        var fromIndex = fromindex
        if (closed) {
            throw IllegalStateException("closed")
        }
        while (true) {
            let result = this.buf.indexOf(bytes, fromIndex)
            if (result != -1) {
                return result
            }
            let lastBufferSize = this.buf.size
            if (source.read(this.buf, Segment.SIZE) == -1) {
                return -1
            }
            fromIndex = max(fromIndex, lastBufferSize - bytes.size + 1)
        }
        return -1
    }

    /**
     * The Function is indexOfElement
     *
     * @param targetBytes of ByteString
     *
     * @return Type of Int64
     * @since 0.32.5
     */
    public override func indexOfElement (targetBytes: ByteString): Int64 {
        return indexOfElement(targetBytes, 0)
    }

    /**
     * The Function is indexOfElement
     *
     * @param targetBytes of ByteString
     * @param fromIndex of Int64
     *
     * @return Type of Int64
     * @since 0.32.5
     */
    public override func indexOfElement (targetBytes: ByteString, fromindex: Int64): Int64 {
        var fromIndex = fromindex
        if (closed) {
            throw IllegalStateException("closed")
        }
        while (true) {
            let result = this.buf.indexOfElement(targetBytes, fromIndex)
            if (result != -1) {
                return result
            }

            let lastBufferSize = this.buf.size
            if (source.read(this.buf, Segment.SIZE) == -1)  {
                return -1
            }
            fromIndex = max(fromIndex, lastBufferSize)
        }
        return 0
    }

    /**
     * The Function is rangeEquals
     *
     * @param offset of Int64
     * @param bytes of ByteString
     *
     * @return Type of Bool
     * @since 0.32.5
     */
    public override func rangeEquals(offset: Int64, bytes: ByteString): Bool {
        return rangeEquals(offset, bytes, 0, bytes.size)
    }

    /**
     * The Function is rangeEquals
     *
     * @param offset of Int64
     * @param bytes of ByteString
     * @param bytesOffset of Int64
     * @param byteCount of Int64
     *
     * @return Type of Bool
     * @since 0.32.5
     */
    public override func rangeEquals(offset: Int64, bytes: ByteString, bytesOffset: Int64, byteCount: Int64): Bool {
        if (closed) {
            throw IllegalStateException("closed")
        }
        if (offset < 0 || bytesOffset < 0 || byteCount < 0 || bytes.size - bytesOffset < byteCount) {
            return false;
        }
        for(i in 0..byteCount) {
            let bufferOffset = offset + i
            if (!request(bufferOffset + 1)) {
                return false
            }
            if (this.buf.getInt8(bufferOffset) != Int8(bytes.getByte(bytesOffset + i))) {
                return false
            }
        }
        return true
    }

    /**
     * The Function is peek
     *
     * @return Type of BufferedSource
     * @since 0.32.5
     */
    public override func peek (): BufferedSource {
        return Okio.buffer(PeekSource(this))
    }

    /**
     * The Function is close
     *
     * @return Type of Unit
     * @since 0.32.5
     */
    public override func close (): Unit {
        if (closed) {
            return
        }
        this.closed = true;
        source.close()
        this.buf.clear()
    }

    /**
     * The Function is timeout
     *
     * @return Type of Timeout
     * @since 0.32.5
     */
    public override func timeout(): Timeout {
        return source.timeout()
    }

    /**
     * The Function is toString
     *
     * @return Type of String
     * @since 0.32.5
     */
    public override func toString (): String {
        return "RealBufferedSource: ${this.buf.toString()}"
    }

    /**
     * The Function is isClosed
     *
     * @return Type of Bool
     * @since 0.32.5
     */
    public override func isClosed(): Bool {
        return !this.closed
    }
}
