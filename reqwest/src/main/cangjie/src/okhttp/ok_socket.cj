/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2022-2024. All rights resvered.
 */

/**
 * @file
 * The file declares the OKSocket class.
 */

package ohos_app_cangjie_reqwest.okhttp

public class OKSocket <: Resource & InputStream & OutputStream {
    public let client: SocketClient
    let readTimeOut: Option<Duration>
    let writeTimeOut: Option<Duration>
    public init(client: SocketClient, readTimeOut: Option<Duration>, writeTimeOut: Option<Duration>) {
        this.client = client
        this.readTimeOut = readTimeOut
        this.writeTimeOut = writeTimeOut
    }

    public func read(buffer: Array<Byte>): Int64 {
        match (readTimeOut) {
            case Some(time) => client.read(buffer, time)
            case None => client.read(buffer)
        }
    }

    public func write(buffer: Array<Byte>): Unit {
        match (writeTimeOut) {
            case Some(time) => client.write(buffer, time)
            case None => client.write(buffer)
        }
    }

    public func close(): Unit {
        client.close()
    }

    public func isClosed(): Bool {
        return client.isClosed()
    }
}

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
            case SocketC(conn) => conn.read(buffer)
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
