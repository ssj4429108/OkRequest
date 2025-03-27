/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2022-2024. All rights resvered.
 */

/**
 * @file
 * The file declars the Okio class.
 */
package ohos_app_cangjie_OkRequest.okio
internal import std.fs.*
internal import compress.zlib.*
internal import std.io.*
internal import std.sync.*
internal import std.math.*
internal import std.collection.*
internal import std.format.*
internal import encoding.hex.*
internal import encoding.base64.*
//internal import ohos_app_cangjie_OkRequest.crypto.md5cj.*
//internal import ohos_app_cangjie_OkRequest.crypto.sha1cj.*
//internal import ohos_app_cangjie_OkRequest.crypto.sha256cj.*
//internal import ohos_app_cangjie_OkRequest.crypto.sha512cj.*
//internal import ohos_app_cangjie_OkRequest.crypto.hmaccj.*
internal import std.time.*
internal import std.socket.*
internal import net.tls.*
import ohos.hilog.Hilog

/**
 * The class is Okio
 * @author liyanqing14
 * @since 0.32.5
 */
public class Okio {

    // Do not expose the constructor to call static functions.
    init (){}

    /**
     * The Function is buffer
     *
     * @param source of Source
     *
     * @return Type of BufferedSource
     * @since 0.32.5
     */
    public static func buffer(source: Source): BufferedSource {
        return RealBufferedSource(source)
    }

    /**
     * The Function is buffer
     *
     * @param sink of Sink
     *
     * @return Type of BufferedSink
     * @since 0.32.5
     */
    public static func buffer(sink: Sink): BufferedSink {
        return RealBufferedSink(sink)
    }

    public static func sink(socket: SocketClient): Sink {
        let timeout = timeout(socket)
        let sink = sink(SocketBuffer(socket), timeout)
        return timeout.sink(sink)
    }

    /**
     * The Function is sink
     *
     * @param socket of Socket
     *
     * @return Type of Sink
     * @since 0.32.5
     */
    public static func sink(socket: TcpSocket): Sink {
        let timeout = timeout(socket)
        let sink = sink(SocketBuffer(socket), timeout)
        return timeout.sink(sink)
    }

    /**
     * The Function is sink
     *
     * @param socket of TlsSocket
     *
     * @return Type of Sink
     * @since 0.32.5
     */
    public static func sink(socket: TlsSocket): Sink {
        let timeout = timeout(socket)
        let sink = sink(SocketBuffer(socket), timeout)
        return timeout.sink(sink)
    }

    // TODO: Later, I need to customize a file object to call parameters. There are many file object parameters in cangjie, which is very troublesome
    /**
     * The Function is sink
     *
     * @param file of File
     *
     * @return Type of Sink
     * @since 0.32.5
     */
    public static func sink(file: File): Sink {
        return sink(file, Timeout())
    }

    public static func source(scoket: SocketClient): Source {
        let timeout = timeout(scoket)
        let source = source(SocketBuffer(scoket), timeout)
        return timeout.source(source)
    }


    /**
     * The Function is source
     *
     * @param socket of Socket
     *
     * @return Type of Source
     * @since 0.32.5
     */
    public static func source(socket: TcpSocket): Source {
        let timeout = timeout(socket)
        let source = source(SocketBuffer(socket), timeout)
        return timeout.source(source)
    }
    /**
     * The Function is source
     *
     * @param socket of TlsSocket
     *
     * @return Type of Source
     * @since 0.32.5
     */
    public static func source(socket: TlsSocket): Source {
        let timeout = timeout(socket)
        let source = source(SocketBuffer(socket), timeout)
        return timeout.source(source)
    }

    /**
     * The Function is source
     *
     * @param file of File
     *
     * @return Type of Source
     * @since 0.32.5
     */
    public static func source(file: File): Source {
        return source(file, Timeout())
    }

    private static func source (input: InputStream, timeout: Timeout) : Source { 
        func subRead (sink: Buffer, byteCount: Int64): Int64 {
            if (byteCount < 0) {
                throw IllegalArgumentException("byteCount < 0")
            }
            if (byteCount == 0) {
                return 0
            }
            try {
                timeout.throwIfReached()

                let tail = sink.writableSegment(1)

                let maxToCopy = min(byteCount, Segment.SIZE - tail.limit)

                let bytesRead = input.read(tail.data[tail.limit .. maxToCopy])

                if (bytesRead == 0) {
                    if (tail.pos == tail.limit) {
                        sink.head = tail.pop()
                        SegmentPool.recycle(tail)
                    }
                    return -1
                }
                tail.limit += bytesRead
                sink.mysize += bytesRead
                return bytesRead
            } catch (e: Exception) {
                throw e
            }
        }
        func subTimeout(): Timeout {
            return timeout
        }
        let source = AnonymousSource()
        source.funRead = subRead
        source.funTimeout = subTimeout
        return source
    }

    private static func sink (out: OutputStream, timeout: Timeout) : Sink {
        func subWrite(source: Buffer, bytecount: Int64): Unit {
            Util.checkOffsetAndCount(source.size, 0, bytecount)
            var byteCount = bytecount
            while (byteCount > 0) {
                timeout.throwIfReached()
                var head = source.head.getOrThrow()
                var toCopy = min(byteCount, head.limit - head.pos)
                out.write(head.data[head.pos..toCopy])
                head.pos += toCopy
                byteCount -= toCopy
                source.mysize -= toCopy
                if (head.pos == head.limit) {
                    source.head = head.pop()
                    SegmentPool.recycle(head)
                }
            }
        }
        func subFlush (): Unit {
            out.flush()
        }
        func subTimeout (): Timeout {
            return timeout
        }
        let sink = AnonymousSink()
        sink.funWrite = subWrite
        sink.funFlush = subFlush
        sink.funTimeout = subTimeout
        return sink
    }

    private static func timeout(socket: TcpSocket): AsyncTimeout {
        func subtimeout (): Unit {
            try {
                socket.close()
            } catch (e: Exception) {
                e.printStackTrace()
            } 
        }
        let ast = AsyncTimeout()
        ast.fun = subtimeout
        return ast
    }

    private static func timeout(socket: SocketClient): AsyncTimeout {
        func subtimeout (): Unit {
            try {
                socket.close()
            } catch (e: Exception) {
                e.printStackTrace()
            } 
        }
        let ast = AsyncTimeout()
        ast.fun = subtimeout
        return ast
    }

    private static func timeout(socket: TlsSocket): AsyncTimeout {
        func subtimeout (): Unit {
            try {
                socket.close()
            } catch (e: Exception) {
                e.printStackTrace()
            } 
        }
        let ast = AsyncTimeout()
        ast.timeout(socket.readTimeout.getOrThrow().toNanoseconds())
        ast.fun = subtimeout
        return ast
    }


}

class AnonymousSource <: Source {
    var funRead: ?(Buffer, Int64)-> Int64 = None
    var funTimeout: ?()-> Timeout = None

    /**
     * The Function is close
     *
     * @return Type of Unit
     * @since 0.32.5
     */
    public override func close(): Unit { }

    /**
     * The Function is read
     *
     * @param sink of Buffer
     * @param byteCount of Int64
     *
     * @return Type of Int64
     * @since 0.32.5
     */
    public override func read(sink: Buffer, byteCount: Int64): Int64 {
        match (this.funRead) {
            case None => -1
            case Some(v) => v(sink, byteCount)
        }
    }

    /**
     * The Function is timeout
     *
     * @return Type of Timeout
     * @since 0.32.5
     */
    public override func timeout(): Timeout {
        return this.funTimeout.getOrThrow()()
    }

    /**
     * The Function is isClosed
     *
     * @return Type of Bool
     * @since 0.32.5
     */
    public override func isClosed(): Bool {false}

    /**
     * The Function is toString
     *
     * @return Type of String
     * @since 0.32.5
     */
    public override func toString(): String{
        return "AnonymousSource"
    }
}


class AnonymousSink <: Sink {
    var funWrite: ?(Buffer, Int64)-> Unit = None
    var funFlush: ?()-> Unit = None
    var funTimeout: ?()-> Timeout = None

    /**
     * The Function is close
     *
     * @return Type of Unit
     * @since 0.32.5
     */
    public override func close(): Unit {}

    /**
     * The Function is flush
     *
     * @return Type of Unit
     * @since 0.32.5
     */
    public override func flush(): Unit {
        match (this.funFlush) {
            case None => ()
            case Some(v) => v()
        }
    }

    /**
     * The Function is timeout
     *
     * @return Type of Timeout
     * @since 0.32.5
     */
    public override func timeout(): Timeout {
        return this.funTimeout.getOrThrow()()
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
        match (this.funWrite) {
            case None => ()
            case Some(v) =>
                v(source, byteCount)
        }
    }

    /**
     * The Function is isClosed
     *
     * @return Type of Bool
     * @since 0.32.5
     */
    public override func isClosed(): Bool {false}

     /**
     * The Function is toString
     *
     * @return Type of String
     * @since 0.32.5
     */
    public override func toString(): String{
        return "AnonymousSink"
    }
}
