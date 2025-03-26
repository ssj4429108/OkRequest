/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2022-2024. All rights resvered.
 */

/**
 * @file
 * The file declars the Utf8 class.
 */
package ohos_app_cangjie_OkRequest.okio

/**
 * The class is Utf8
 * @author liyanqing14
 * @since 0.32.5
 */
public class Utf8 {

    /**
     * The Function is size
     *
     * @param str of String
     *
     * @return Type of Int64
     * @since 0.32.5
     */
    public static func size(str: String): Int64 {
        size(str, 0, str.size)
    }

    /**
     * The Function is size
     *
     * @param str of String
     * @param beginIndex of Int64
     * @param endIndex of Int64
     *
     * @return Type of Int64
     * @since 0.32.5
     */
    public static func size(str: String, beginIndex: Int64, endIndex: Int64): Int64 {
        if (beginIndex < 0) {
            throw IllegalArgumentException ("beginIndex < 0: ${beginIndex}.")
        }
        if (beginIndex > endIndex) {
            throw IllegalArgumentException ("endIndex < beginIndex: ${endIndex} < ${beginIndex}")
        }
        if (endIndex > str.size) {
            throw IllegalArgumentException ("endIndex > string.length: ${endIndex}> ${str.size}")
        }
        var result: Int64 = 0
        var i = beginIndex
        while (i < endIndex) {
            let char = UInt32(str[i])
            if (char < 0x80) {
                result++
                i++
            }
            else if (char < 0x800) {
                result += 2
                i++
            }
            else if (char < 0xd800 || char > 0xdfff) {
                result += 3
                i++
            }
            else {
                let low: UInt32 = if (i + 1 < endIndex) {
                    UInt32(str[i +1])
                } else {
                    0x00
                }
                if (char > 0xdbff || low <0xdc00 || low > 0xdfff) {
                    result++
                    i++
                } else {
                    result += 4
                    i += 2
                }
            }
        }
        return result
    } 
}


