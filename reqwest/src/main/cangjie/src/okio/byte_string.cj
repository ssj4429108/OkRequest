/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2022-2024. All rights resvered.
 */

/**
 * @file
 * The file declars the ByteString class.
 */
package ohos_app_cangjie_OkRequest.okio


let MAP: Array<UInt8> = [65, 66, 67, 68, 69, 70, 71, 72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87, 88, 89, 90, 97, 98, 99, 100, 101, 102, 103, 104, 105, 106, 107, 108, 109, 110, 111, 112, 113, 114, 115, 116, 117, 118, 119, 120, 121, 122, 48, 49, 50, 51, 52, 53, 54, 55, 56, 57, 43, 47]
let NULL_CHAR = unsafe{ zeroValue<Rune>() }
let HEX_DIGITS: Array<Byte> = "0123456789abcdef".toArray()
/**
 * The class is ByteString inherited from Object & Hashable & ToString & Equatable<ByteString>
 * @author liyanqing14
 * @since 0.32.5
 */
public open class ByteString <: Object & Hashable & ToString & Equatable<ByteString> {
    
    let data: Array<Byte>

    protected var hashcode: Int64 = 0
    
    protected var utf8: ?String = None

    /**
     * The Function is init constructor
     *
     * @param data of Array<Byte>
     * @since 0.32.5
     */
    public init (data: Array<Byte>){
        this.data = data
    }

    init (data: String){
        this.utf8 = data
        this.data = data.toArray()
    }

    /**
     * The Function is of
     *
     * @param data of Array<Byte>
     *
     * @return Type of ByteString
     * @since 0.32.5
     */
    public static func of (data: Array<Byte>): ByteString {
        return ByteString(data.clone())
    }

    /**
     * The Function is of
     *
     * @param target of Array<Byte>
     * @param offset of Int64
     * @param byteCount of Int64
     *
     * @return Type of ByteString
     * @since 0.32.5
     */
    public static func of(target: Array<Byte>, offset: Int64, byteCount: Int64): ByteString {
        let bytes: Array<Byte> = Array<Byte>(byteCount, item: 0)
        var i = 0
        while (i < byteCount) {
            bytes[i] = target[i + offset]
            i++
        }
        return ByteString(bytes)
    }

    /**
     * The Function is encodeUtf8
     *
     * @param s of String
     *
     * @return Type of ByteString
     * @since 0.32.5
     */
    // Returns a new byte string containing the {@code UTF-8} bytes of {@code s}. */
    public static func encodeUtf8(s: String): ByteString {
        return ByteString(s)
    }

    /**
     * The Function is UTF8
     *
     * @return Type of String
     * @since 0.32.5
     */
    /** Constructs a new {@code String} by decoding the bytes as {@code UTF-8}. */
    public func UTF8(): String {
        match (this.utf8) {
            case Some(v) => return v
            case None => 
                let result = unsafe {String.fromUtf8Unchecked(this.data)}
                this.utf8 = result
                return result
        }
    }


    /**
     * The Function is base64
     *
     * @return Type of String
     * @since 0.32.5
     */
    public func base64 (): String {
        return encode(this.data, MAP)
    }

    @OverflowWrapping
    protected func encode(input: Array<Byte>, map: Array<Byte>): String {
        let length = (input.size + 2) / 3 * 4
        let out = Array<Byte>(length, item: NULL)
        var index = 0
        var end = input.size - input.size % 3
        for (i in 0..end:3) {
            out[index] = map[(Int64(input[i]) & 255) >> 2]
            index++
            out[index] = map[(Int64(input[i]) & 3) << 4 | (Int64(input[i + 1]) & 255) >> 4]
            index++
            out[index] = map[(Int64(input[i + 1]) & 15) << 2 | (Int64(input[i + 2]) & 255) >> 6]
            index++
            out[index] = map[Int64(input[i + 2]) & 63]
            index++
        }
        match (Int64(input.size % 3)) {
            case 1 => 
                out[index] = map[(Int64(input[end]) & 255) >> 2]
                index++
                out[index] = map[(Int64(input[end]) & 3) << 4]
                index++
                out[index] = 61
                index++
                out[index] = 61
                index++
            case 2 => 
                out[index] = map[(Int64(input[end]) & 255) >> 2]
                index++
                out[index] = map[(Int64(input[end]) & 3) << 4 | (Int64(input[end + 1]) & 255) >> 4]
                index++
                out[index] = map[(Int64(input[end + 1]) & 15) << 2]
                index++
                out[index] = 61
                index++
            case _ => ()
        }
        return unsafe {String.fromUtf8Unchecked(out)}
    }

    /**
     * The Function is decodeBase64
     *
     * @param base64 of String
     *
     * @return Type of ?ByteString
     * @since 0.32.5
     */
    public static func decodeBase64 (base64: String): ?ByteString {
        match (decode(base64)) {
            case Some(arr) => return ByteString(arr)
            case None =>  return None
        }
    }

    @OverflowWrapping
    protected static func decode(input: String): ?Array<Byte> {
        var limit = input.size
        while (limit > 0) {
            let c = Rune(UInt32(input[limit - 1]))
            if (c != r'=' && c != r'\n' && c != r'\r' && c != r' ' && c != r'\t') {
                break
            }
            limit--
        }
        let out = Array<Byte>(limit * 6 / 8, item: 0)
        var outCount = 0
        var inCount = 0
        var word = 0
        for (pos in 0..limit) {
            let c = Rune(UInt32(input[pos]))
            var bits = 0
            if (c >= r'A' && c <= r'Z') {
                bits = Int64(UInt32(c)) - 65
            } else if (c >= r'a' && c <= r'z') {
                bits = Int64(UInt32(c)) - 71
            } else if (c >= r'0' && c <= r'9') {
                bits = Int64(UInt32(c)) + 4
            } else if (c == r'+' || c == r'-') {
                bits = 62
            } else if (c == r'/' || c == r'_') {
                bits = 63
            } else if (c == r'\n' || c == r'\r' || c == r' ' || c == r'\t') {
                continue
            } else {
                return None
            }
            word = (word << 6) | Int64(Int8(bits))
            inCount++;
            if (inCount % 4 == 0) {
                out[outCount] = UInt8(word >> 16)
                outCount++
                out[outCount] = UInt8(word >> 8)
                outCount++
                out[outCount] = UInt8(word)
                outCount++
            }
        }
        let lastWordChars = inCount % 4
        if (lastWordChars == 1) {
            return None
        } else if (lastWordChars == 2) {
            word = word << 12
            out[outCount] = UInt8(word >> 16)
            outCount++
        } else if (lastWordChars == 3) {
            word = word << 6;
            out[outCount] = UInt8(word >> 16)
            outCount++
            out[outCount] = UInt8(word >> 8)
            outCount++
        }
        if (outCount == out.size){
            return out
        }
        return out[0..outCount]
    }

    /**
     * The Function is hex
     *
     * @return Type of String
     * @since 0.32.5
     */
    public func hex(): String {
        let chars: Array<Byte> = Array<Byte>(this.data.size * 2, item: NULL)
        var c = 0
        for (d in 0..this.data.size) {
            chars[c] = HEX_DIGITS[Int64((data[d] >> 4) & 0x0f)]
            c++
            chars[c] = HEX_DIGITS[Int64(data[d] & 0x0f)]
            c++
        }
        return String.fromUtf8(chars)
    }


    /**
     * The Function is decodeHexdecodeHex
     *
     * @param hex of String
     *
     * @return Type of ByteString
     * @since 0.32.5
     */
    @OverflowWrapping
    public static func decodeHex(hex: String): ByteString {
        if (hex.size % 2 != 0) {
            throw IllegalArgumentException("Unexpected hex string: ${hex}")
        }
        let result = Array<Byte>(hex.size / 2, item: NULL)
        for (i in 0..result.size) {
            let d1 = decodeHexDigit(Rune(UInt32(hex[i * 2]))) << 4
            let d2 = decodeHexDigit(Rune(UInt32(hex[i * 2 + 1])))
            result[i] = UInt8(d1 + d2)
        }
        return ByteString(result)
    }

    protected static func decodeHexDigit(c: Rune): UInt32 {
        if (c >= r'0' && c <= r'9') {
            return UInt32(c) - UInt32(r'0')
        }
        if (c >= r'a' && c <= r'f') {
            return UInt32(c) - UInt32(r'a') + 10
        }
        if (c >= r'A' && c <= r'F') {
            return UInt32(c) - UInt32(r'A') + 10
        }
        throw IllegalArgumentException("Unexpected hex digit: ${c}")
    }

    /**
     * The Function is read
     *
     * @param input of InputStream
     * @param byteCount of Int64
     *
     * @return Type of ByteString
     * @since 0.32.5
     */
    public static func read(input: InputStream, byteCount: Int64): ByteString {
        if (byteCount < 0) {
            throw IllegalArgumentException("byteCount < 0")
        }
        let arr = Array<Byte>(byteCount, item: 0)
        try {
            input.read(arr)
        } catch (e: Exception) {
            throw EOFException(e.toString())
        }
        return ByteString(arr)
    }

    /**
     * The Function is read
     *
     * @param path of String
     *
     * @return Type of ByteString
     * @since 0.32.5
     */
    public static func read(path: String): ByteString {
        let src = File(path, Open(true, false))
        return read(src,src.length)
    }

    /**
     * The Function is toAsciiLowercase
     *
     * @return Type of ByteString
     * @since 0.32.5
     */
    public func toAsciiLowercase (): ByteString {
        let arr = this.data.clone()
        var index = 0
        while (index < this.data.size) {
            arr[index] = UInt8(UInt32(Rune(this.data[index]).toAsciiLowerCase()))
            index++
        }
        return ByteString(arr)
    }

    /**
     * The Function is toAsciiUppercase
     *
     * @return Type of ByteString
     * @since 0.32.5
     */
    public func toAsciiUppercase (): ByteString {
        let arr = this.data.clone()
        var index = 0
        while (index < this.data.size) {
            arr[index] = UInt8(UInt32(Rune(this.data[index]).toAsciiUpperCase()))
            index++
        }
        return ByteString(arr)
    }

    /**
     * The Function is substring
     *
     * @param beginIndex of Int64
     *
     * @return Type of ByteString
     * @since 0.32.5
     */
    public func substring(beginIndex: Int64): ByteString {
        return substring(beginIndex, data.size)
    }

    /**
     * The Function is substring
     *
     * @param beginIndex of Int64
     * @param endIndex of Int64
     *
     * @return Type of ByteString
     * @since 0.32.5
     */
    public func substring(beginIndex: Int64, endIndex: Int64): ByteString {
        if (beginIndex < 0) {
            throw IllegalArgumentException("beginIndex < 0")
        }
        if (endIndex > this.data.size) {
            throw IllegalArgumentException("endIndex > size(${data.size})")
        }
        let subLen = endIndex - beginIndex
        if (subLen < 0 ) {
            throw IllegalArgumentException("endIndex : ${endIndex} < beginIndex : ${beginIndex}")
        }
        if (beginIndex == 0 && endIndex == this.data.size) {
            return this
        }
        let copy = Array<Byte>(subLen, item: 0)
        ArrayCopy(this.data, beginIndex, copy, 0, subLen)
        return ByteString(copy)
    }

    /**
     * The Function is getByte
     *
     * @param pos of Int64
     *
     * @return Type of Byte
     * @since 0.32.5
     */
    public func getByte (pos: Int64): Byte {
        return this.data[pos]
    }

    /**
     * let member size type is Int64 {
     * @since 0.32.5
     */
    public prop size: Int64 {
        get () {
            return this.data.size
        }
    }

    /**
     * The Function is toByteArray
     *
     * @return Type of Array<Byte>
     * @since 0.32.5
     */
    public func toByteArray (): Array<Byte> {
        return this.data.clone()
    }

    func internalArray(): Array<Byte> {
        return this.data
    }

    /**
     * The Function is write
     *
     * @param outPath of String
     * @param mode of OpenMode, and the Default value is Append
     *
     * @return Type of Unit
     * @since 0.32.5
     */
    public func write (outPath: String): Unit {
        write(File(outPath, OpenOption.CreateOrAppend))
        // write(File(outPath, Write, mode))
    }

    /**
     * The Function is write
     *
     * @param out of OutputStream
     *
     * @return Type of Unit
     * @since 0.32.5
     */
    public func write (out: OutputStream): Unit {
        out.write(this.data)
    }

    /**
     * The Function is write
     *
     * @param buffer of Buffer
     * @since 0.32.5
     */
    public func write (buffer: Buffer) {
        buffer.write(this.data, 0, data.size)
    }

    /**
     * The Function is rangeEquals
     *
     * @param offset of Int64
     * @param other of ByteString
     * @param otherOffset of Int64
     * @param byteCount of Int64
     *
     * @return Type of Bool
     * @since 0.32.5
     */
    public func rangeEquals(offset: Int64, other: ByteString, otherOffset: Int64, byteCount: Int64): Bool {
        return other.rangeEquals(otherOffset, this.data, offset, byteCount)
    }

    /**
     * The Function is rangeEquals
     *
     * @param offset of Int64
     * @param other of Array<Byte>
     * @param otherOffset of Int64
     * @param byteCount of Int64
     *
     * @return Type of Bool
     * @since 0.32.5
     */
    public func rangeEquals(offset: Int64, other: Array<Byte>, otherOffset: Int64, byteCount: Int64): Bool {
        return offset >= 0 && offset <= data.size - byteCount
        && otherOffset >= 0 && otherOffset <= other.size - byteCount
        && Util.arrayRangeEquals(data, offset, other, otherOffset, byteCount)
    }

    /**
     * The Function is startsWith
     *
     * @param prefix of ByteString
     *
     * @return Type of Bool
     * @since 0.32.5
     */
    public func startsWith(prefix: ByteString): Bool {
        return rangeEquals(0, prefix, 0, prefix.size)
    }

    /**
     * The Function is startsWith
     *
     * @param prefix of Array<Byte>
     *
     * @return Type of Bool
     * @since 0.32.5
     */
    public func startsWith(prefix: Array<Byte>): Bool {
        return rangeEquals(0, prefix, 0, prefix.size)
    }   

    /**
     * The Function is endsWith
     *
     * @param suffix of ByteString
     *
     * @return Type of Bool
     * @since 0.32.5
     */
    public func endsWith (suffix: ByteString):Bool {
        return rangeEquals(this.size - suffix.size, suffix, 0, suffix.size)
    }

    /**
     * The Function is endsWith
     *
     * @param suffix of Array<Byte>
     *
     * @return Type of Bool
     * @since 0.32.5
     */
    public func endsWith (suffix:Array<Byte>) :Bool {
        return rangeEquals(this.size - suffix.size, suffix, 0, suffix.size)
    }

    /**
     * The Function is indexOf
     *
     * @param other of ByteString
     *
     * @return Type of Int64
     * @since 0.32.5
     */
    public func indexOf(other: ByteString): Int64 {
        return indexOf(other.internalArray(), 0)
    }

    /**
     * The Function is indexOf
     *
     * @param other of ByteString
     * @param fromIndex of Int64
     *
     * @return Type of Int64
     * @since 0.32.5
     */
    public func indexOf(other: ByteString, fromIndex: Int64): Int64 {
        return indexOf(other.internalArray(), fromIndex)
    }

    /**
     * The Function is indexOf
     *
     * @param other of Array<Byte>
     *
     * @return Type of Int64
     * @since 0.32.5
     */
    public func indexOf(other: Array<Byte>): Int64 {
        return indexOf(other, 0)
    }

    /**
     * The Function is indexOf
     *
     * @param other of Array<Byte>
     * @param fromIndex of Int64
     *
     * @return Type of Int64
     * @since 0.32.5
     */
    public func indexOf(other: Array<Byte>, fromIndex: Int64): Int64 {
        for (i in max(fromIndex, 0)..=data.size-other.size where Util.arrayRangeEquals(this.data, i, other, 0, other.size)) {
            return i
        }
        return -1
    }

    /**
     * The Function is lastIndexOf
     *
     * @param other of ByteString
     *
     * @return Type of Int64
     * @since 0.32.5
     */
    public func lastIndexOf(other: ByteString) : Int64 {
        return lastIndexOf(other.internalArray(), this.size)
    }

    /**
     * The Function is lastIndexOf
     *
     * @param other of ByteString
     * @param fromIndex of Int64
     *
     * @return Type of Int64
     * @since 0.32.5
     */
    public func lastIndexOf(other: ByteString, fromIndex: Int64): Int64 {
        return lastIndexOf(other.internalArray(), fromIndex)
    }

    /**
     * The Function is lastIndexOf
     *
     * @param other of Array<Byte>
     *
     * @return Type of Int64
     * @since 0.32.5
     */
    public func lastIndexOf(other: Array<Byte>): Int64 {
        return lastIndexOf(other, this.size)
    }

    /**
     * The Function is lastIndexOf
     *
     * @param other of Array<Byte>
     * @param fromIndex of Int64
     *
     * @return Type of Int64
     * @since 0.32.5
     */
    public func lastIndexOf(other: Array<Byte>, fromIndex: Int64): Int64 {
        for (i in min(fromIndex, data.size - other.size)..=0:-1 where Util.arrayRangeEquals(this.data, i, other, 0, other.size)) {
            return i
        }
        return -1
    }

    /**
     * The Function is ==
     *
     * @param that of ByteString
     *
     * @return Type of Bool
     * @since 0.32.5
     */
    public operator func == (that: ByteString): Bool {
        return this.equals(that)
    }

    /**
     * The Function is !=
     *
     * @param that of ByteString
     *
     * @return Type of Bool
     * @since 0.32.5
     */
    public operator func != (that: ByteString): Bool {
        return !(this == that)
    }

    /**
     * The Function is equals
     *
     * @param o of ByteString
     *
     * @return Type of Bool
     * @since 0.32.5
     */
    public func equals (o: ByteString): Bool {
        if (refEq(this, o)) {
            return true
        }
        if (o.size != this.size) {
            return false
        }
        for (index in 0..this.size where this.data[index] != o.data[index]) {
            return false
        }
        return true
    }

    /**
     * The Function is hashCode
     *
     * @return Type of Int64
     * @since 0.32.5
     */
    @OverflowWrapping
    public func hashCode (): Int64 {
        return if (this.hashcode != 0) {
            this.hashcode
        } else {
            var result: Int32 = 1
            for (i in 0..this.data.size) {
                result = result * 31 + Int32(Int8(this.data[i]))
            }
            this.hashcode = Int64(result)
            this.hashcode
        }
    }

    /**
     * The Function is toString
     *
     * @return Type of String
     * @since 0.32.5
     */
    public func toString (): String {
        if ( this.data.size == 0) {
            return "[size=0]"
        }
        let text = UTF8()
        let safeText = text.replace("\\", "\\\\")
                            .replace("\n", "\\n")
                            .replace("\r", "\\r")
        return "[text=${safeText}]"
    }
}

