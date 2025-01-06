/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2022-2024. All rights resvered.
 */
package ohos_app_cangjie_reqwest.okhttp

/*
 * md5
 */
class MD5 {
    var data: Array<UInt8> = Array<UInt8>(64, item: 0)
    var datalen: Int64 = 0
    var bitlen: Int64 = 0
    var state: Array<UInt32> = [0x67452301, 0xEFCDAB89, 0x98BADCFE, 0x10325476]
    var hash: Array<UInt8> = Array<UInt8>(16, item: 0)

    /*
     * 计算字符串 md5 值
     */
    public static func digest(src: String): String {
        var md5 = MD5()
        let buf = src.toUtf8Array()
        md5.update(buf)
        return toHexString(md5.final())
    }

    private func ROTLEFT(a: UInt32, b: UInt32): UInt32 {
        ((a << b) | (a >> (32 - b)))
    }
    private func F(x: UInt32, y: UInt32, z: UInt32): UInt32 {
        ((x & y) | (!x & z))
    }
    private func G(x: UInt32, y: UInt32, z: UInt32): UInt32 {
        ((x & z) | (y & (!z)))
    }
    private func H(x: UInt32, y: UInt32, z: UInt32): UInt32 {
        (x ^ y ^ z)
    }
    private func I(x: UInt32, y: UInt32, z: UInt32): UInt32 {
        (y ^ (x | (!z)))
    }

    @OverflowWrapping
    private func FF(a: UInt32, b: UInt32, c: UInt32, d: UInt32, m: UInt32, s: UInt32, t: UInt32): UInt32 {
        var a1: UInt32 = a + F(b, c, d) + m + t
        a1 = b + ROTLEFT(a1, s)
        return a1
    }

    @OverflowWrapping
    private func GG(a: UInt32, b: UInt32, c: UInt32, d: UInt32, m: UInt32, s: UInt32, t: UInt32): UInt32 {
        var a1: UInt32 = a + G(b, c, d) + m + t
        a1 = b + ROTLEFT(a1, s)
        return a1
    }

    @OverflowWrapping
    private func HH(a: UInt32, b: UInt32, c: UInt32, d: UInt32, m: UInt32, s: UInt32, t: UInt32): UInt32 {
        var a1: UInt32 = a + H(b, c, d) + m + t
        a1 = b + ROTLEFT(a1, s)
        return a1
    }

    @OverflowWrapping
    private func II(a: UInt32, b: UInt32, c: UInt32, d: UInt32, m: UInt32, s: UInt32, t: UInt32): UInt32 {
        var a1: UInt32 = a + I(b, c, d) + m + t
        a1 = b + ROTLEFT(a1, s)
        return a1
    }
    public func update(other: Array<UInt8>) {
        for (i in 0..other.size) {
            this.data[this.datalen] = other[i]
            this.datalen = this.datalen + 1
            if (this.datalen == 64) {
                transform()
                this.bitlen = this.bitlen + 512
                this.datalen = 0
            }
        }
    }
    public func final(): Array<UInt8> {
        return checkSum()
    }

    @OverflowWrapping
    func checkSum(): Array<UInt8> {
        var i: Int64 = this.datalen

        if (this.datalen < 56) {
            // 高位填1，剩余位填0
            this.data[i] = UInt8(0b1000_0000)
            i = i + 1
            while (i < 56) {
                this.data[i] = 0x00
                i = i + 1
            }
        } else {
            this.data[i] = UInt8(0b1000_0000)
            i = i + 1
            while (i < 64) {
                this.data[i] = UInt8(0x00)
                i = i + 1
            }
            transform()
            for (j in 0..56) {
                this.data[j] = 0
            }
        }

        this.bitlen = this.bitlen + (this.datalen * 8)
        this.data[56] = UInt8(this.bitlen)
        this.data[57] = UInt8(this.bitlen >> 8)
        this.data[58] = UInt8(this.bitlen >> 16)
        this.data[59] = UInt8(this.bitlen >> 24)
        this.data[60] = UInt8(this.bitlen >> 32)
        this.data[61] = UInt8(this.bitlen >> 40)
        this.data[62] = UInt8(this.bitlen >> 48)
        this.data[63] = UInt8(this.bitlen >> 56)
        transform()

        for (j in 0..4) {
            hash[j] = UInt8((this.state[0] >> (j * 8)) & 0x000000ff)
            hash[j + 4] = UInt8((this.state[1] >> (j * 8)) & 0x000000ff)
            hash[j + 8] = UInt8((this.state[2] >> (j * 8)) & 0x000000ff)
            hash[j + 12] = UInt8((this.state[3] >> (j * 8)) & 0x000000ff)
        }
        return hash
    }

    @OverflowWrapping
    private func transform() {
        var m: Array<UInt32> = Array<UInt32>(16, item: 0)

        var j: Int64 = 0
        for (i in 0..16) {
            m[i] = UInt32(this.data[j]) + (UInt32(this.data[j + 1]) << 8) + (UInt32(this.data[j + 2]) << 16) + (UInt32(this.
                    data[j + 3]) << 24)
            j += 4
        }
        var a: UInt32 = this.state[0]
        var b: UInt32 = this.state[1]
        var c: UInt32 = this.state[2]
        var d: UInt32 = this.state[3]

        a = FF(a, b, c, d, m[0], 7, 0xd76aa478)
        d = FF(d, a, b, c, m[1], 12, 0xe8c7b756)
        c = FF(c, d, a, b, m[2], 17, 0x242070db)
        b = FF(b, c, d, a, m[3], 22, 0xc1bdceee)
        a = FF(a, b, c, d, m[4], 7, 0xf57c0faf)
        d = FF(d, a, b, c, m[5], 12, 0x4787c62a)
        c = FF(c, d, a, b, m[6], 17, 0xa8304613)
        b = FF(b, c, d, a, m[7], 22, 0xfd469501)
        a = FF(a, b, c, d, m[8], 7, 0x698098d8)
        d = FF(d, a, b, c, m[9], 12, 0x8b44f7af)
        c = FF(c, d, a, b, m[10], 17, 0xffff5bb1)
        b = FF(b, c, d, a, m[11], 22, 0x895cd7be)
        a = FF(a, b, c, d, m[12], 7, 0x6b901122)
        d = FF(d, a, b, c, m[13], 12, 0xfd987193)
        c = FF(c, d, a, b, m[14], 17, 0xa679438e)
        b = FF(b, c, d, a, m[15], 22, 0x49b40821)

        a = GG(a, b, c, d, m[1], 5, 0xf61e2562)
        d = GG(d, a, b, c, m[6], 9, 0xc040b340)
        c = GG(c, d, a, b, m[11], 14, 0x265e5a51)
        b = GG(b, c, d, a, m[0], 20, 0xe9b6c7aa)
        a = GG(a, b, c, d, m[5], 5, 0xd62f105d)
        d = GG(d, a, b, c, m[10], 9, 0x02441453)
        c = GG(c, d, a, b, m[15], 14, 0xd8a1e681)
        b = GG(b, c, d, a, m[4], 20, 0xe7d3fbc8)
        a = GG(a, b, c, d, m[9], 5, 0x21e1cde6)
        d = GG(d, a, b, c, m[14], 9, 0xc33707d6)
        c = GG(c, d, a, b, m[3], 14, 0xf4d50d87)
        b = GG(b, c, d, a, m[8], 20, 0x455a14ed)
        a = GG(a, b, c, d, m[13], 5, 0xa9e3e905)
        d = GG(d, a, b, c, m[2], 9, 0xfcefa3f8)
        c = GG(c, d, a, b, m[7], 14, 0x676f02d9)
        b = GG(b, c, d, a, m[12], 20, 0x8d2a4c8a)

        a = HH(a, b, c, d, m[5], 4, 0xfffa3942)
        d = HH(d, a, b, c, m[8], 11, 0x8771f681)
        c = HH(c, d, a, b, m[11], 16, 0x6d9d6122)
        b = HH(b, c, d, a, m[14], 23, 0xfde5380c)
        a = HH(a, b, c, d, m[1], 4, 0xa4beea44)
        d = HH(d, a, b, c, m[4], 11, 0x4bdecfa9)
        c = HH(c, d, a, b, m[7], 16, 0xf6bb4b60)
        b = HH(b, c, d, a, m[10], 23, 0xbebfbc70)
        a = HH(a, b, c, d, m[13], 4, 0x289b7ec6)
        d = HH(d, a, b, c, m[0], 11, 0xeaa127fa)
        c = HH(c, d, a, b, m[3], 16, 0xd4ef3085)
        b = HH(b, c, d, a, m[6], 23, 0x04881d05)
        a = HH(a, b, c, d, m[9], 4, 0xd9d4d039)
        d = HH(d, a, b, c, m[12], 11, 0xe6db99e5)
        c = HH(c, d, a, b, m[15], 16, 0x1fa27cf8)
        b = HH(b, c, d, a, m[2], 23, 0xc4ac5665)

        a = II(a, b, c, d, m[0], 6, 0xf4292244)
        d = II(d, a, b, c, m[7], 10, 0x432aff97)
        c = II(c, d, a, b, m[14], 15, 0xab9423a7)
        b = II(b, c, d, a, m[5], 21, 0xfc93a039)
        a = II(a, b, c, d, m[12], 6, 0x655b59c3)
        d = II(d, a, b, c, m[3], 10, 0x8f0ccc92)
        c = II(c, d, a, b, m[10], 15, 0xffeff47d)
        b = II(b, c, d, a, m[1], 21, 0x85845dd1)
        a = II(a, b, c, d, m[8], 6, 0x6fa87e4f)
        d = II(d, a, b, c, m[15], 10, 0xfe2ce6e0)
        c = II(c, d, a, b, m[6], 15, 0xa3014314)
        b = II(b, c, d, a, m[13], 21, 0x4e0811a1)
        a = II(a, b, c, d, m[4], 6, 0xf7537e82)
        d = II(d, a, b, c, m[11], 10, 0xbd3af235)
        c = II(c, d, a, b, m[2], 15, 0x2ad7d2bb)
        b = II(b, c, d, a, m[9], 21, 0xeb86d391)

        this.state[0] = this.state[0] + a
        this.state[1] = this.state[1] + b
        this.state[2] = this.state[2] + c
        this.state[3] = this.state[3] + d
    }
}
