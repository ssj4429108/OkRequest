/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2022-2024. All rights resvered.
 */

/**
 * @file
 * The file declars the SegmentPool class.
 */
package ohos_app_cangjie_OkRequest.okio

/**
 * The class is SegmentPool
 * @author liyanqing14
 * @since 0.32.5
 */
public class SegmentPool {

    static let MAX_SIZE = 64 * 1024

    static let mutex = ReentrantMutex()

    static var next: ?Segment = None 

    static var byteCount = 0

    static func take(): Segment {
        synchronized (mutex) {
            match(next) {
                case Some(result) => 
                    next = result.next
                    result.next = None
                    byteCount -= Segment.SIZE
                    return result
                case None => ()
            }
        }
        return Segment()
    }

    static func recycle(segment: Segment) {
        match(segment.prev) {
            case None => ()
            case _ => throw IllegalArgumentException()
        }
        match(segment.next) {
            case None => ()
            case _ => throw IllegalArgumentException()
        }
        if (segment.shared) {
            return
        }
        synchronized (mutex) {
            if (byteCount + Segment.SIZE > MAX_SIZE) {
                return
            }
            byteCount += Segment.SIZE
            segment.next = next
            segment.pos = 0
            segment.limit = 0
            next = Some(segment)
        }
    }
}

