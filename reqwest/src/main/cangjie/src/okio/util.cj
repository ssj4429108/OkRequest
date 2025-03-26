/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2022-2024. All rights resvered.
 */

/**
 * @file
 * The file declars the Util class.
 */

package ohos_app_cangjie_OkRequest.okio

/*
 * The class is Util
 * @author liyanqing14
 * @since 0.32.5
 */
class Util {
    private init(){}

    /**
     * The Function is checkOffsetAndCount
     *
     * @param size of Int64
     * @param offset of Int64
     * @param byteCount of Int64
     * @since 0.32.5
     */
    public static func checkOffsetAndCount (size: Int64, offset: Int64, byteCount: Int64) {
        if ((offset | byteCount) < 0 || offset > size || size - offset < byteCount ) {
            throw ArrayIndexOutOfBoundsException()
        }
    }

    /**
     * The Function is reverseBytesInt16
     *
     * @param s of Int16
     *
     * @return Type of Int16
     * @since 0.32.5
     */
    @OverflowWrapping
    public static func reverseBytesInt16(s: Int16): Int16 {
        let i: UInt16 = UInt16(s) & 0xffff
        return Int16((i & 0xff00) >> 8 | (i & 0x00ff) << 8)
    }

    /**
     * The Function is reverseBytesInt32
     *
     * @param s of Int32
     *
     * @return Type of Int32
     * @since 0.32.5
     */
    @OverflowWrapping
    public static func reverseBytesInt32(s: Int32): Int32 {
        let i: UInt32 = UInt32(s) & 0xffffffff
        return Int32( (i & 0xff000000) >> 24
                    | (i & 0x00ff0000) >> 8
                    | (i & 0x0000ff00) << 8
                    | (i & 0x000000ff) << 24)
    }

    /**
     * The Function is reverseBytesInt64
     *
     * @param s of Int64
     *
     * @return Type of Int64
     * @since 0.32.5
     */
    @OverflowWrapping
    public static func reverseBytesInt64(s: Int64): Int64 {
        let i: UInt64 = UInt64(s) & 0xffffffffffffffff
        return Int64( (i & 0xff00000000000000) >> 56
                    | (i & 0x00ff000000000000) >> 40
                    | (i & 0x0000ff0000000000) >> 24
                    | (i & 0x000000ff00000000) >> 8
                    | (i & 0x00000000ff000000) << 8
                    | (i & 0x0000000000ff0000) << 24
                    | (i & 0x000000000000ff00) << 40
                    | (i & 0x00000000000000ff) << 56)
    }

    /**
     * The Function is arrayRangeEquals
     *
     * @param a of Array<Byte>
     * @param aOffset of Int64
     * @param b of Array<Byte>
     * @param bOffset of Int64
     * @param byteCount of Int64
     *
     * @return Type of Bool
     * @since 0.32.5
     */
    public static func arrayRangeEquals(a: Array<Byte>, aOffset: Int64, b: Array<Byte>, bOffset: Int64, byteCount: Int64): Bool {
        for (i in 0..byteCount where a[i + aOffset] != b[i + bOffset]) {
            return false
        }
        return true
    }

    /**
     * The Function is sneakyRethrow
     *
     * @param t of Exception
     *
     * @return Type of Exception
     * @since 0.32.5
     */

    public static func sneakyRethrow(t: Exception) {
        Util.sneakyRethrow2(t)
    }

    /**
     * The Function is sneakyRethrow2
     *
     * @param t of Exception
     *
     * @return Type of Exception
     * @since 0.32.5
     */

    private static func sneakyRethrow2(t: Exception): Exception {
        throw t
    }
}
