/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2022-2024. All rights resvered.
 */

/**
 * @file
 * The file declars the Segment class.
 */
package ohos_app_cangjie_OkRequest.okio

let NULL = unsafe{ zeroValue<Byte>() }
/**
 * The class is Segment inherited from Object & Equatable<Segment>
 * @author liyanqing14
 * @since 0.32.5
 */
public class Segment <: Object & Equatable<Segment> {
    public static let SIZE = 8192
    static let SHARE_MINIMUM = 1024
    let data: Array<Byte>
    var pos: Int64
    var limit: Int64
    var shared: Bool
    var owner: Bool
    var next: ?Segment = Option.None
    var prev: ?Segment = Option.None

    /**
     * The Function is init constructor
     *
     * @since 0.32.5
     */
    public init() {
        this.data = Array<UInt8>(SIZE, item: NULL)
        this.pos = 0
        this.limit = 0
        this.shared = false
        this.owner = true
    }

    /**
     * The Function is init constructor
     *
     * @param data of Array<UInt8>
     * @param pos of Int64
     * @param limit of Int64
     * @param shared of Bool
     * @param owner of Bool
     * @since 0.32.5
     */
    public init(data: Array<UInt8>, pos: Int64, limit: Int64, shared: Bool, owner: Bool) {
        this.data = data
        this.pos = pos
        this.limit = limit
        this.shared = shared
        this.owner = owner
    }

    func sharedCopy(): Segment {
        shared = true
        return Segment(this.data, this.pos, this.limit, true, false)
    }

    /**
     * The Function is push
     *
     * @param segment of Segment
     *
     * @return Type of Segment
     * @since 0.32.5
     */
    public func push(segment: Segment): Segment {
        segment.prev = this
        segment.next = next
        next?.prev = segment
        next = segment
        return segment
    }

    /**
     * The Function is pop
     *
     * @return Type of ?Segment
     * @since 0.32.5
     */
    public func pop(): ?Segment {
        let nextA = next.getOrThrow()
        let result: ?Segment = if (nextA != this) {
            next
        } else {
            None
        }
        prev?.next = next
        next?.prev = prev
        next = None
        prev = None
        return result
    }

    /*
     *  Split the head of the circular linked list into two sections.
     *  The first paragraph contains the data in [pos.. Pos+byteCount),
     *  The second paragraph contains the data in [pos+byteCount.. Limit],
     *  It is useful to move some segments from one buffer to another.
     */
    public func split(byteCount: Int64): Segment {
        if (byteCount <= 0 || byteCount > limit - pos) {
            throw IllegalArgumentException()
        }
        var prefix: Segment
        if (byteCount >= SHARE_MINIMUM) {
            prefix = sharedCopy()
        } else {
            prefix = SegmentPool.take()
            data.copyTo(prefix.data, 0, 0, byteCount)
        }
        prefix.limit = prefix.pos + byteCount
        pos += byteCount
        prev?.push(prefix)
        return prefix
    }

    /**
     * The Function is compact
     *
     * @since 0.32.5
     */
    public func compact() {
        match (prev) {
            case Some(seg) => doCompact(seg)
            case None =>
                1
                ()
        }
    }

    func doCompact(prev: Segment) {
        if (!prev.owner) {
            return
        }
        let byteCount = limit - pos
        let availableByteCount = SIZE - prev.limit + (if (prev.shared) {
            0
        } else {
            prev.pos
        })
        if (byteCount > availableByteCount) {
            return
        }
        writeTo(prev, byteCount);
        pop();
        SegmentPool.recycle(this);
    }

    /**
     * The Function is writeTo
     *
     * @param sink of Segment
     * @param byteCount of Int64
     * @since 0.32.5
     */
    public func writeTo(sink: Segment, byteCount: Int64) {
        if (!sink.owner) {
            throw IllegalArgumentException()
        }
        if (sink.limit + byteCount > SIZE) {
            if (sink.shared) {
                throw IllegalArgumentException()
            }
            if (sink.limit + byteCount - sink.pos > SIZE) {
                throw IllegalArgumentException()
            }
            data.copyTo(sink.data, sink.pos, 0, sink.limit - sink.pos);
            sink.limit -= sink.pos
            sink.pos = 0
        }
        data.copyTo(sink.data, pos, sink.limit, byteCount);
        sink.limit += byteCount
        pos += byteCount
    }
    /**
     * The Function is ==
     *
     * @param that of Segment
     *
     * @return Type of Bool
     * @since 0.32.5
     */
    public operator func ==(that: Segment): Bool {
        return refEq(this, that)
    }
    /**
     * The Function is !=
     *
     * @param that of Segment
     *
     * @return Type of Bool
     * @since 0.32.5
     */
    public operator func !=(that: Segment): Bool {
        return !refEq(this, that)
    }
}
