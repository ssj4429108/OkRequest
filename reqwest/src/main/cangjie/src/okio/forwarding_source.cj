/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2022-2024. All rights resvered.
 */

/**
 * @file
 * The file declars the ForwardingSource class.
 */
package ohos_app_cangjie_OkRequest.okio

public open class ForwardingSource <: Source{

    /**
     * let member source type is Source
     * @since 0.33.3
     */
    private var source: Source
    private var closed: Bool = false

    /**
     * The Function is init constructor
     *
     * @param source of Source
     * @since 0.33.3
     */
    public init(source: Source){
        this.source = source;
    }

    /**
     * The Function is getDelegate
     *
     * @return Type of Source
     * @since 0.33.3
     */
    public func delegate(): Source{
        return source
    }

    /**
     * The Function is isClosed
     *
     * @return Type of Bool
     * @since 0.34.3
     */
    public open func isClosed(): Bool {
        source.isClosed()
    } 

    /**
     * The Function is read
     *
     * @param sink of Buffer
     * @param byteCount of Int64
     *
     * @return Type of Int64
     * @since 0.33.3
     */
    public override open func read(sink: Buffer,byteCount:Int64): Int64{
        return source.read(sink,byteCount)
    }

    /**
     * The Function is timeout
     *
     * @return Type of Timeout
     * @since 0.33.3
     */
    public override func timeout(): Timeout{
        return source.timeout()
    }

    /**
     * The Function is close
     *
     * @return Type of Unit
     * @since 0.33.3
     */
    public override func close(): Unit {
        source.close()
    }

    /**
     * The Function is toString
     *
     * @return Type of String
     * @since 0.33.3
     */
    public override func toString(): String{
        return "Source" + "(" + source.toString() + ")"
    }
}
