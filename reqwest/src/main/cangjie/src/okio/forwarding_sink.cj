/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2022-2024. All rights resvered.
 */

/**
 * @file
 * The file declars the ForwardingSink abstract class.
 */

package ohos_app_cangjie_OkRequest.okio
import ohos.hilog.Hilog

public open class ForwardingSink <: Sink {
    
    /**
     * let member delegate type is Sink
     * @since 0.33.3
     */
    private var sink: Sink
    private var closed: Bool = false
    
    /**
     * The Function is init constructor
     *
     * @param delegate of Sink
     * @since 0.33.3
     */
    public init(sink: Sink) {
 
    this.sink = sink
    }

    /**
     * The Function is getDelegate
     *
     * @return Type of Sink
     * @since 0.33.3
     */
    public func delegate(): Sink{
        return sink
    }

    /**
     * The Function is isClosed
     *
     * @return Type of Bool
     * @since 0.34.3
     */
    public open override func isClosed(): Bool {
        sink.isClosed()
    } 

    /**
     * The Function is write
     *
     * @param source of Buffer
     * @param byteCount of Int64
     *
     * @return Type of Unit
     * @since 0.33.3
     */
    public override open func write(source: Buffer,byteCount: Int64): Unit {
        sink.write(source,byteCount)
    }

    /**
     * The Function is flush
     *
     * @return Type of Unit
     * @since 0.33.3
     */
    public open override func flush(): Unit {
        sink.flush()
    }

    /**
     * The Function is timeout
     *
     * @return Type of Timeout
     * @since 0.33.3
     */
    public override func timeout(): Timeout{
        return sink.timeout()
    }

    /**
     * The Function is close
     *
     * @return Type of Unit
     * @since 0.33.3
     */
    public open override func close(): Unit {
        sink.close()
    }

    /**
     * The Function is toString
     *
     * @return Type of String
     * @since 0.33.3
     */
    public override func toString(): String{
        return "Sink" + "(" + sink.toString() + ")"
  
    }
}
