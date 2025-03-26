/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2022-2024. All rights resvered.
 */

/**
 * @file
 * The file declars the GzipSink class.
 */

package ohos_app_cangjie_OkRequest.okio
import ohos.hilog.Hilog

public class GzipSink <: Sink {

    private var sink: BufferedSink
    public var deflaterSink: DeflaterSink
    public var closed: Bool = false


    /**
     * The Function is init constructor
     *
     * @since 0.34.3
     */
    public init(sink: Sink){
        this.sink = Okio.buffer(sink)
        this.deflaterSink = DeflaterSink(this.sink)
    }

    /**
     * The Function is write
     *
     * @param source of Buffer
     * @param byteCount of Int64
     *
     * @return Type of Unit
     * @since 0.34.3
     */
    public func write(source: Buffer,byteCount: Int64): Unit {
        if (byteCount < 0) {
            throw IllegalArgumentException("byteCount < 0: ${byteCount}")
        }
        if (byteCount == 0){
            return
        }
        updateCrc(source, byteCount)
        deflaterSink.write(source, byteCount)
    }

    /**
     * The Function is flush
     *
     * @return Type of Unit
     * @since 0.34.3
     */
    public override func flush(): Unit {
        Hilog.info(3, "ok-request", "flush111144")
        sink.flush()
    }

    /**
     * The Function is timeout
     *
     * @since 0.34.3
     */
    public override func timeout(): Timeout{
        return sink.timeout()
    }

    /**
     * The Function is close
     *
     * @return Type of Unit
     * @since 0.34.3
     */
    public override func close(): Unit{
        if(this.closed){
            return
        }
        var thrown: ?Exception = None
        try {
            this.sink.close()
        } catch (e: Exception) {
            match (thrown) {
                    case None => thrown = e
                    case Some(v) => () 
                }
        }
        closed = true
        match (thrown) {
            case None => ()
            case Some(v) => Util.sneakyRethrow(thrown.getOrThrow())
        }
    }
    
    /**
     * The Function is updateCrc
     *
     * @param source of Buffer
     * @param byteCount of Int64
     *
     * @return Type of Unit
     * @since 0.34.3
     */
    private func updateCrc(buffer: Buffer, bytecount: Int64): Unit{
        var head: Segment = buffer.head.getOrThrow()
        var byteCount = bytecount
        while(byteCount > 0){
            var segmentLength: Int64 = min(byteCount, head.limit - head.pos)
            update(head.data , head.pos , segmentLength)
            head = head.next.getOrThrow()
            byteCount -=  segmentLength
        }
    }

    /**
     * The Function is isClosed
     *
     *@return Type of Bool
     * @since 0.34.3
     */
    public override func isClosed(): Bool {
        return sink.isClosed()
    } 

    /**
     * The Function is toString
     *
     *@return Type of String
     * @since 0.34.3
     */
    public override func toString():String{
        return sink.toString()
    }

    /**
     * The Function is update
     *
     * @param b of Array<Byte>
     * @param off of Int64
     * @param len of Int64
     *
     * @return Type of Unit
     * @since 0.34.3
     */
    func update(b: Array<Byte> , off: Int64 , len: Int64):Unit {
        if (off < 0 || len < 0 || off > b.size - len) {
            throw ArrayIndexOutOfBoundsException()
        }
        updateBytes(b, off, len)
    }

    /**
     * The Function is updateBytes
     *
     * @param crc of Int64
     * @param b of Array<Byte>
     * @param off of Int64
     * @param len of Int64
     *
     * @return Type of Unit
     * @since 0.34.3
     */
    func updateBytes(b: Array<Byte> , off: Int64 , len: Int64):Unit {
        updateBytesCheck(b , off , len)

    }

    /**
     * The Function is updateBytesCheck
     *
     * @param b of Array<Byte>
     * @param off of Int64
     * @param len of Int64
     *
     * @return Type of Unit
     * @since 0.34.3
     */
    func updateBytesCheck(b: Array<Byte> , off: Int64 , len: Int64):Unit {
        if (len <= 0) {
            return
        }
        if (b.size == 0) {
            throw NoneValueException()
        }
        if (off < 0 || off >= b.size) {
            throw ArrayIndexOutOfBoundsException()
        }
        let endIndex: Int64 = off + len -1
        if (endIndex < 0 || endIndex >= b.size) {
            throw ArrayIndexOutOfBoundsException()
        }
    }
 }
