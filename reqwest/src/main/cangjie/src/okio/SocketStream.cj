/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2022-2024. All rights resvered.
 */

/**
 * @file
 * The file declars the SockClient enum.
 */
package ohos_app_cangjie_OkRequest.okio
import ohos.hilog.Hilog




public enum SocketClient <: Resource {
    | SocketC(TcpSocket)
    | TlsC(TlsSocket)

    public func connect(): Unit {
        match (this) {
            case SocketC(conn) => conn.connect()
            case TlsC(conn) =>
                (conn.socket as TcpSocket)?.connect()
                conn.handshake()
        }
    }

    public func connect(timeout: Duration): Unit {
        match (this) {
            case SocketC(conn) => conn.connect(timeout: timeout)
            case TlsC(conn) =>
                (conn.socket as TcpSocket)?.connect(timeout: timeout)
                conn.handshake(timeout: timeout)
        }
    }

    public func read(buffer: Array<Byte>): Int64 {
        return match (this) {
            case SocketC(conn) =>
                Hilog.info(3, "ok-request", "socket read start: ${conn}")
                conn.readTimeout = Duration.second * 3
                let res = conn.read(buffer)
                Hilog.info(3, "ok-request", "socket read end")
                res
            case TlsC(conn) => conn.read(buffer)
        }
    }

    public func read(buffer: Array<Byte>, timeout: Duration): Int64 {
        return match (this) {
            case SocketC(conn) =>
                conn.readTimeout = timeout
                conn.read(buffer)
            case TlsC(conn) =>
                conn.readTimeout = timeout
                conn.read(buffer)
        }
    }

    public func write(buffer: Array<Byte>): Unit {
        match (this) {
            case SocketC(conn) => conn.write(buffer)
            case TlsC(conn) => conn.write(buffer)
        }
    }

    public func write(buffer: Array<Byte>, timeout: Duration): Unit {
        match (this) {
            case SocketC(conn) =>
                conn.writeTimeout = timeout
                conn.write(buffer)
            case TlsC(conn) =>
                conn.writeTimeout = timeout
                conn.write(buffer)
        }
    }

    public func close(): Unit {
        return match (this) {
            case SocketC(conn) => conn.close()
            case TlsC(conn) => conn.close()
        }
    }

    public func isClosed(): Bool {
        return match (this) {
            case SocketC(conn) => conn.isClosed()
            case TlsC(conn) => conn.isClosed()
        }
    }
}

/**
 * The class is SocketBuffer inherited from InputStream & OutputStream & Resource & ToString
 * @author liyanqing14
 * @since 0.32.5
 */
public open class SocketBuffer <: InputStream & OutputStream & Resource & ToString {

    var sockClient: SocketClient 
    let lock = ReentrantMutex()
    var closed: Bool = false

    /**
     * The Function is init constructor
     *
     * @param sockClient of Socket
     * @since 0.32.5
     */
    public init(sockClient: StreamingSocket) {
        this.sockClient = match(sockClient) {
            case v: TcpSocket => SocketC(v)
            case v: TlsSocket => TlsC(v)
            case _ => throw Exception("The SocketBuffer is invalid")
        }
    }

    public init(socketClient: SocketClient) {
        this.sockClient = socketClient
    }

    // Disable
    /**
     * let member length type is Int64 {
     * @since 0.32.5
     */
    public open prop length: Int64 {
        get() { -1 }
    }

    /**
     * The Function is write
     *
     * @param buffer of Array<Byte>
     *
     * @return Type of Unit
     * @since 0.32.5
     */
    public open func write(buffer: Array<Byte>): Unit {
        synchronized(lock) {this.sockClient.write(buffer)}
    }
    /**
     * The Function is flush
     *
     * @return Type of Unit
     * @since 0.32.5
     */
    public open func flush(): Unit {
        synchronized(lock) {}
    }

    /**
     * The Function is read
     *
     * @param buffer of Array<Byte>
     *
     * @return Type of Int64
     * @since 0.32.5
     */
    public open func read(buffer: Array<Byte>): Int64 {
        synchronized(lock) {this.sockClient.read(buffer)}
    }

    /**
     * The Function is isClosed
     *
     * @return Type of Bool
     * @since 0.32.5
     */
    public open func isClosed(): Bool {
        synchronized(lock) {this.closed}
    }

    /**
     * The Function is close
     *
     * @return Type of Unit
     * @since 0.32.5
     */
    public open func close(): Unit {
        synchronized(lock) {
            this.sockClient.close()
            this.closed = true
        }
        
    }

    /**
     * The Function is toString
     *
     * @return Type of String
     * @since 0.32.5
     */
    public open func toString(): String {
        synchronized(lock) {
            match (this.sockClient) {
                case SocketC(v) => v.toString()
                case TlsC(v) => v.toString()
            }
        }
    }
}
