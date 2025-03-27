/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2022-2024. All rights resvered.
 */

/**
 * @file
 * The file declars the Pipe class.
 */

package ohos_app_cangjie_OkRequest.okio
import ohos.hilog.Hilog

    var sinkClosed: Bool = false
    var sourceClosed: Bool = false
    let buffer: Buffer = Buffer()
    let mtx: ReentrantMutex = ReentrantMutex()
    let monitor: Monitor = Monitor()
    var foldedSink: ?Sink = Option.None
    var maxBufferSize: Int64 = 0
public class Pipe {

    private let psink: Sink = PipeSink()
    private let psource: Source = PipeSource()
    
    public init(bufferSize: Int64) {
        if (bufferSize < 1) {
            throw IllegalArgumentException("maxBufferSize < 1: ${bufferSize}")
        }

        maxBufferSize = bufferSize
    }

    public func source(): Source {
        return psource
    }

    public func sink(): Sink {
        return psink
    }

    public func fold(sink: Sink) {
        while (true) {
            var closed: Bool = false
            var foldbuffer: Buffer
            synchronized(monitor){
                match (foldedSink) {
                    case None => ()
                    case Some(v) => throw IllegalStateException("sink already folded")
                }
                if (buffer.exhausted()) {
                    sourceClosed = true
                    foldedSink = sink
                    return
                }
                closed = sinkClosed
                foldbuffer = Buffer()
                foldbuffer.write(buffer,buffer.size)
            }
            var success: Bool = false
            try {
                sink.write(foldbuffer, foldbuffer.size)
                if (closed) {
                    sink.close()
                } else {
                    sink.flush()
                }
                success = true
            } finally{
                if (!success) {
                    synchronized(monitor){
                        sourceClosed = true
                    }
                }
            }
        }
    }

}

class PipeSink <: Sink {

    let ptimeout: PushableTimeout = PushableTimeout()

    public override func write(source: Buffer , bytecount: Int64): Unit {
        var byteCount: Int64 = bytecount
        var sink: ?Sink = Option.None
        synchronized(monitor){
            if (sinkClosed) {
                throw IllegalStateException("closed")
            }
            while (byteCount > 0) {
                match (foldedSink) {
                    case None => ()
                    case Some(v) => sink = foldedSink
                    break
                }
            if (sourceClosed) {
                throw Exception("source is closed")
            }
            let bufferSpaceAvailable: Int64 = maxBufferSize - buffer.size
            if (bufferSpaceAvailable == 0) {
                ptimeout.waitUntilNotified(monitor)
                continue
            }
            let bytesToWrite: Int64 = min(bufferSpaceAvailable, byteCount)
            buffer.write(source , bytesToWrite)
            byteCount -= bytesToWrite

            }
        }
        
        match (sink) {
            case None => ()
            case Some(v) => 
                ptimeout.push(sink.getOrThrow().timeout())
                match (sink) {
                    case None => ()
                    case Some(v) =>  ptimeout.push(sink.getOrThrow().timeout())
                }

                try {
                    sink.getOrThrow().write(source, byteCount)
                } finally{
                    ptimeout.pop()
                }
        }
    }

    public override func flush() {
        var sink: ?Sink = Option.None
        synchronized(monitor){
            if (sinkClosed) {
                throw IllegalStateException("closed")
            }
            match (foldedSink) {
                case Some(v) => 
                    sink = foldedSink
                    case None => if (sourceClosed && buffer.size > 0) {
                    throw Exception("source is closed")
                    }
            }
        }

        match (sink) {
            case None => ()
            case Some(v) =>
                ptimeout.push(sink.getOrThrow().timeout())
                try {
                    sink.getOrThrow().flush()
                } finally{
                    ptimeout.pop()
                }
        }
    }

    public override func close() {
        var sink: ?Sink = Option.None
        synchronized(monitor) {
            if (sinkClosed) {
                sink = foldedSink
            } else {
                if (sourceClosed && buffer.size > 0) {
                    throw Exception("source is closed")
                }
                    sinkClosed = true
            }
        }
        match (sink) {
            case None => ()
            case Some(v) => 
                ptimeout.push(sink.getOrThrow().timeout())
                try {
                    sink.getOrThrow().close()
                } finally{
                    ptimeout.pop()
                }
        }
    }

    public override func timeout(): Timeout {
        return ptimeout
    }
    
    /**
     * The Function is isClosed
     *
     * @return Type of Bool
     * @since 0.33.3
     */
    public override func isClosed(): Bool {
        return sinkClosed
    } 

    /**
     * The Function is toString
     *
     *@return Type of String
     * @since 0.33.3
     */
    public override func toString():String{
        return foldedSink.getOrThrow().toString()
    }

}

class PipeSource <: Source {

    let ptimeout: Timeout = Timeout()

    public override func read(sink: Buffer , byteCount: Int64): Int64 {
        synchronized(monitor){
            if (sourceClosed) {
                throw IllegalStateException("close")
            }
            while (buffer.size == 0) {
                if (sinkClosed) {
                    return -1
                }
                ptimeout.waitUntilNotified(monitor)
            }

            let result: Int64 = buffer.read(sink , byteCount)
            return result
        }
    }

    public override func close(){
        synchronized(monitor){
            sourceClosed = true
        }
    }

    public override func timeout(): Timeout {
        return ptimeout
    }
    
    /**
     * The Function is isClosed
     *
     *@return Type of Bool
     * @since 0.33.3
     */
    public override func isClosed(): Bool {
        return sourceClosed
    } 

    /**
     * The Function is toString
     *
     *@return Type of String
     * @since 0.33.3
     */
    public override func toString():String{
        return foldedSink.getOrThrow().toString()
    }
}
