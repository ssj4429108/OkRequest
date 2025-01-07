/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2022-2024. All rights resvered.
 */

/**
 * @file
 * The file declars the Address class.
 */

package ohos_app_cangjie_OkRequest.okhttp

/*
 * The class is HttpException inherited from RuntimeException
 * @author guo_tingtingtekla,luoyukai4
 * @since 0.29.3
 */
public open class HttpException <: Exception {
    /**
     * The Function is init constructor
     *
     * @param message of String
     * @since 0.29.3
     */
    public init(message: String) {
        super(message)
    }
    public open func toString(): String {
        "HttpException: ${message}"
    }
}

public class EOFException <: Exception {
    /**
     * The Function is init constructor
     *
     * @param message of String
     * @since 0.36.4
     */
    public init(message: String) {
        super(message)
    }

    /**
     * The Function is init constructor
     *
     * @param message of String
     * @since 0.36.4
     */
    public init() {
        super("EOF")
    }
    public func toString(): String {
        "EOFException: ${message}"
    }
}

public class RouteException <: Exception {
    private let firstException: HttpException
    private var lastException: HttpException
    public init(message: String, e: HttpException) {
        super(message)
        this.firstException = e
        this.lastException = e
    }
    public func getFirstConnectException(): HttpException {
        return firstException
    }
    public func getLastConnectException(): HttpException {
        return lastException
    }
    public func toString(): String {
        "RouteException: ${message}"
    }
}

public class ConnectException <: HttpException {
    public let contain: Exception
    public init(message: String, e: Exception) {
        super(message)
        this.contain = e
    }
    public func toString(): String {
        "ConnectException: ${message}"
    }
}

public class ProtocolException <: HttpException {
    public init(message: String) {
        super(message)
    }
    public func toString(): String {
        "ProtocolException: ${message}"
    }
}

public class ConnectionShutdownException <: HttpException {
    public init(message: String) {
        super(message)
    }
    public func toString(): String {
        "ConnectionShutdownException: ${message}"
    }
}

// public class IllegalStateException <: Exception {
//     public init(message: String) {
//         super(message)
//     }
//     public func toString(): String {
//         "IllegalStateException: ${message}"
//     }
// }

public class StreamResetException <: HttpException {
    public let errorCode: ErrorCode
    public init(errorCode: ErrorCode) {
        super("stream was reset: ${errorCode.toString()}")
        this.errorCode = errorCode
    }
    public func toString(): String {
        "StreamResetException: ${message}"
    }
}
