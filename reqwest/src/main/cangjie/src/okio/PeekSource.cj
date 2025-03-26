/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2022-2024. All rights resvered.
 */

/**
 * @file
 * The file declars the PeekSource class.
 */

package ohos_app_cangjie_OkRequest.okio

class PeekSource <: Source & ToString{

    var closed: Bool = false
    var pos: Int64 = 0
    var expectedPos: Int64 = 0
    var expectedSegment: ?Segment
    var buffer: Buffer
    var upstream: BufferedSource

    init (upstream: BufferedSource) {
        this.upstream = upstream
        this.buffer = upstream.getBuffer()
        this.expectedSegment = buffer.head
        this.expectedPos = match (buffer.head) {
            case None => -1
            case Some(v) => v.pos
        }
    }

    /**
     * The Function is read
     *
     * @param sink of Buffer
     * @param byteCount of Int64
     *
     * @return Type of Int64
     * @since 0.32.5
     */
    public func read(sink: Buffer, byteCount: Int64): Int64 {
        if (byteCount < 0) {
            throw IllegalArgumentException("byteCount < 0: ${byteCount}")
        }
        if (this.closed) {
            throw IllegalArgumentException("closed")
        }
        if (this.expectedSegment.getOrThrow() != this.buffer.head.getOrThrow() || this.expectedPos != this.buffer.head.getOrThrow().pos) {
            throw IllegalArgumentException("Peek source is invalid because upstream source was used")
        }
        if (byteCount == 0) {
            return 0
        }
        match ((this.expectedSegment, this.buffer.head)) {
            case (None, Some(v)) =>
                this.expectedSegment = v
                this.expectedPos = v.pos
            case _ => ()
        }
        let toCopy = min(byteCount, buffer.size - this.pos)
        this.buffer.copyTo(sink, this.pos, toCopy)
        this.pos += toCopy
        return toCopy

    }
    /**
     * The Function is close
     *
     * @return Type of Unit
     * @since 0.32.5
     */
    public func close(): Unit {
        this.closed = true
    }
    /**
     * The Function is timeout
     *
     * @return Type of Timeout
     * @since 0.32.5
     */
    public func timeout(): Timeout {
        return Timeout()  // TODO
    }

    /**
     * The Function is isClosed
     *
     * @return Type of Bool
     * @since 0.32.5
     */
    public func isClosed(): Bool {
        return this.closed
    }

    /**
     * The Function is toString
     *
     * @return Type of String
     * @since 0.32.5
     */
    public override func toString(): String{
        return this.toString()
    }
}
