/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2022-2024. All rights resvered.
 */

/**
 * @file The file declars the ByteBuffer class.
 */

package ohos_app_cangjie_reqwest.okhttp

let HUFF_SYM: UInt16 = 0b1000_0000_0000_0000
let HUFF_ACCEPTED: UInt16 = 0b100_0000_0000_0000

/**
 * Huff encode count func.
 *
 * @return the Int64
 */
func huff_encode_count(arr: Array<UInt8>): Int64 {
    var bits: Int64 = 0
    for (i in 0..arr.size) {
        bits += Int64(HUFF_SYM_TABLE[Int64(arr[i])][0])
    }
    return (bits + VAILD_BIT) / BYTE_SIZE
}

/**
 * Huff encode func.
 *
 * @return the func
 */
@OverflowWrapping
func huff_encode(bufs: ArrayList<UInt8>, arr: Array<UInt8>) {
    var bits: Int64 = 0
    var index = bufs.size
    var code: UInt64 = 0
    var avail: Int64 = bufs.capacity() - index

    for (i in 0..arr.size) {
        let sym = HUFF_SYM_TABLE[Int64(arr[i])]
        code |= UInt64(UInt64(sym[1]) << (32 - bits))
        bits += Int64(sym[0])
        if (bits < 32) {
            continue
        }
        if (avail >= 4) {
            let temp = code >> 32
            bufs.append(UInt8((temp >> 24) & 0xff))
            bufs.append(UInt8((temp >> 16) & 0xff))
            bufs.append(UInt8((temp >> 8) & 0xff))
            bufs.append(UInt8(temp & 0xff))
            avail -= 4
            index += 4
            bits -= 32
            code <<= UInt64(32)
            continue
        }

        while (bits >= 8) {
            bufs.append(UInt8(code >> 56))
            index += 1
            bits -= 8
            code <<= UInt64(8)
        }
        avail = bufs.capacity() - index
    }

    while (bits >= 8) {
        bufs.append(UInt8(code >> 56))
        code <<= UInt64(8)
        index += 1
        bits -= 8
    }

    if (bits != 0) {
        bufs.append(UInt8(code >> 56) | UInt8(((1 << (8 - bits)) - 1)))
        index += 1
    }
}

/**
 * The type Huff decode context.
 */
/* fstate is the current huffman decoding state. */
class HuffDecodeContext {
    public var fstate: UInt16
    public HuffDecodeContext(f: UInt16) {
        fstate = f
    }
}

func huff_decode(ctx: HuffDecodeContext, buf: Array<UInt8>, arr: Array<UInt8>, _: Bool) {
    var node: (UInt16, UInt8) = (ctx.fstate, 0)
    var index = 0
    for (s in 0..arr.size) {
        node = HUFF_DECODE_TABLE[Int64(node[0]) & 0x1ff][Int64(arr[s] >> 4)]

        if ((node[0] & HUFF_SYM) != 0) {
            buf[index] = node[1]
            index++
        }
        node = HUFF_DECODE_TABLE[Int64(node[0]) & 0x1ff][Int64(arr[s] & 0xf)]
        if ((node[0] & HUFF_SYM) != 0) {
            buf[index] = node[1]
            index++
        }
    }
    ctx.fstate = node[0]
    return index
}
