/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2022-2024. All rights resvered.
 */

/**
 * @file
 * The file declars the DeflaterSink class.
 */

package ohos_app_cangjie_OkRequest.okio



public class DeflaterSink {

    private var sink: BufferedSink
    private var sinks: Sink
    private var closed: Bool = false
    private var bufferSink: Buffer = Buffer()
    private var byteCountSink: Int64 = 0

    /**
     * The Function is init constructor
     *
     * @since 0.34.3
     */
    public init(sink: Sink ){
        this.sink = Okio.buffer(sink)
        this.sinks = sink
    }

    /**
     * The Function is isClosed
     *
     * @return Type of Bool
     * @since 0.34.3
     */
    public func isClosed(): Bool{
        sinks.isClosed()
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
    public func write(source: Buffer , byteCount: Int64){
        deflate(source , byteCount)
        this.bufferSink = source
        this.byteCountSink = byteCount
    }

    /**
     * The Function is deflate
     *
     * @param source of Buffer
     * @param byteCount of Int64
     *
     * @return Type of Unit
     * @since 0.34.3
     */
    private func deflate (source: Buffer , byteCount: Int64): Unit {
        let buffer: Buffer = sink.buffer()
        
            let byteSink: Array<Byte> = Array<Byte>(byteCount, item: 0)
            let gzipBuffer: Array<Byte> = Array<Byte>(byteCount, item: 0)
            var result = source.read(byteSink)

            var file:File = File("./temporarily.txt" , OpenOption. CreateOrTruncate(true))
            file.write(byteSink)
            file.seek(SeekPosition.Begin(0))
            var compressInputStream: CompressInputStream = CompressInputStream(file , wrap: DeflateFormat)

        while(true){
            
            let deflated: Int64 = compressInputStream.read(gzipBuffer)
            if(deflated <= 0) {
                break
            }
            buffer.write(gzipBuffer.slice(0, deflated).toArray())
            sinks.write(buffer,buffer.size)

        }
        compressInputStream.close()
        file.close()
    }


}

