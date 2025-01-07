/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2022-2024. All rights resvered.
 */
/**
 * @file The file declares the Settings class.
 */

package ohos_app_cangjie_OkRequest.okhttp

/**
 * Settings describe characteristics of the sending peer, which are used by the receiving peer.
 * Settings are H2Connection scoped
 *
 * @author luoyukai4
 * @since 0.34.3
 */
public class Settings {
    public static let DEFAULT_INITIAL_WINDOW_SIZE = 65535

    /** HTTP/2: Size in bytes of the table used to decode the sender's header blocks. */
    public static let HEADER_TABLE_SIZE = 1

    /** HTTP/2: The peer must not send a PUSH_PROMISE frame when this is 0. */
    public static let ENABLE_PUSH = 2

    /** Sender's maximum number of concurrent streams. */
    public static let MAX_CONCURRENT_STREAMS = 4

    /** HTTP/2: Size in bytes of the largest frame payload the sender will accept. */
    public static let MAX_FRAME_SIZE = 5

    /** HTTP/2: Advisory only. Size in bytes of the largest header list the sender will accept. */
    public static let MAX_HEADER_LIST_SIZE = 6

    /** Window size in bytes. */
    public static let INITIAL_WINDOW_SIZE = 7

    /** Total number of settings. */
    static let COUNT = 10

    private var set = 0

    private let values: Array<Int64> = Array<Int64>(COUNT, item: 0)

    /**
     * The Function is setting
     *
     * @param id of Int64
     * @param value of Int64
     *
     * @return Type of Settings
     * @since 0.34.3
     */
    public func setting(id: Int64, value: Int64): Settings {
        if (id < 0 || id >= values.size) {
            return this
        }
        let bit = 1 << id
        set |= bit
        values[id] = value
        return this
    }

    public func isSet(id: Int64): Bool {
        let bit = 1 << id
        return (set & bit) != 0
    }

    public func get(id: Int64): Int64 {
        return values[id]
    }

    public func size(): Int64 {
        var i = set
        var count = 0
        while (i > 0) {
            i = i & (i - 1)
            count++
        }
        return count
    }

    public func getHeaderTableSize(): Int64 {
        let bit = 1 << HEADER_TABLE_SIZE
        if ((bit & set) != 0) {
            return values[HEADER_TABLE_SIZE]
        } else {
            return -1
        }
    }

    public func getMaxConcurrentStreams(defaultValue: Int64): Int64 {
        let bit = 1 << MAX_CONCURRENT_STREAMS
        if ((bit & set) != 0) {
            return values[MAX_CONCURRENT_STREAMS]
        } else {
            return defaultValue
        }
    }

    public func getMaxFrameSize(defaultValue: Int64): Int64 {
        let bit = 1 << MAX_FRAME_SIZE
        if ((bit & set) != 0) {
            return values[MAX_FRAME_SIZE]
        } else {
            return defaultValue
        }
    }

    public func getInitialWindowSize(): Int64 {
        let bit = 1 << INITIAL_WINDOW_SIZE
        if ((bit & set) != 0) {
            return values[INITIAL_WINDOW_SIZE]
        } else {
            return DEFAULT_INITIAL_WINDOW_SIZE
        }
    }

    /*
     * The Function is merge
     *
     * @param other of Settings
     * @since 0.34.3
     */
    public func merge(other: Settings) {
        for (i in 0..COUNT) {
            if (!other.isSet(i)) {
                continue
            }
            setting(i, other.get(i))
        }
    }
}
