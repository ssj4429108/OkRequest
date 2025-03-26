/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2022-2024. All rights resvered.
 */

/**
 * @file
 * The file declars the InflaterSource class.
 */

package ohos_app_cangjie_OkRequest.okio
public class InflaterSource <: Source {

    private var source: Source
    private var bufferBytesHeldByInflater: Int64 = 0
    private var closed: Bool = false

    /**
     * The Function is init constructor
     *
     * @since 0.34.3
     */
    public init(source: Source) {
        this.source = source
    }

    /**
     * The Function is read
     *
     * @param sink of Buffer
     * @param byteCount of Int64
     *
     * @return Type of Int64
     * @since 0.34.3
     */
    public func read(sink: Buffer , byteCount: Int64): Int64 {
        let buffer: Buffer = Buffer()
        if (byteCount < 0) {
            throw IllegalArgumentException("byteCount < 0: ${byteCount}")
        }
        if (closed) {
            throw IllegalStateException("closed")
        }
        if (byteCount == 0) {
            return 0
        }
            var sourceArray: Array<UInt8> = Array<UInt8>(1024, item: 0)
            var tempBuf: Array<UInt8> = Array<UInt8>(1024, item: 0)
            var file: File = File("./temporar.txt" , OpenOption. CreateOrTruncate(true))
            while(true){
                var index = source.read(buffer,1024)
                buffer.read(tempBuf)
                file.write(tempBuf)

                if(index <= 0) {
                    break
                }
            }
            file.seek(SeekPosition.Begin(0))
            var decompressInputStream: DecompressInputStream = DecompressInputStream(file, wrap: DeflateFormat)

        while(true){
            var readNum = decompressInputStream.read(sourceArray)
            if (readNum <= 0) {
                return -1
                }
            let mins = min(readNum,byteCount)
            let sourceData= String.fromUtf8(sourceArray)[0..readNum].toArray()
            sink.write(sourceData.slice(0,mins).toArray())

        }
        decompressInputStream.close()
        file.close()
        return 0
    }

    /**
     * The Function is timeout
     *
     * @return Type of Timeout
     * @since 0.34.3
     */
    public override func timeout(): Timeout {
        return source.timeout()
    }

    /**
     * The Function is close
     *
     * @return Type of Unit
     * @since 0.34.3
     */
    public override func close():Unit {
        if (closed) {
            return
        }
            closed = true
            source.close()
    }
    
    /**
     * The Function is isClosed
     *
     *@return Type of Bool
     * @since 0.34.3
     */
    public override func isClosed(): Bool {
        return source.isClosed()
    } 

    /**
     * The Function is toString
     *
     *@return Type of String
     * @since 0.34.3
     */
    public override func toString():String{
        return source.toString()
    }

}
