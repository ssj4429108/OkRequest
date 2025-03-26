/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2022-2024. All rights resvered.
 */

/**
 * @file
 * The file declars the BufferedSource interface.
 */

package ohos_app_cangjie_OkRequest.okio

/**
 * The interface is BufferedSource inherited from Source & ToString
 * @author liyanqing14
 * @since 0.32.5
 */
public interface BufferedSource <: Source & ToString {
    /*
     * The Function is getBuffer
     *
     * @return Type of Buffer
     * @since 0.32.5
     */
    func getBuffer(): Buffer
    /*
     * The Function is exhausted
     *
     * @return Type of Bool
     * @since 0.32.5
     */
    func exhausted(): Bool
    /*
     * The Function is require
     *
     * @param byteCount of Int64
     *
     * @return Type of Unit
     * @since 0.32.5
     */
    func require(byteCount: Int64): Unit
    /*
     * The Function is request
     *
     * @param byteCount of Int64
     *
     * @return Type of Bool
     * @since 0.32.5
     */
    func request(byteCount: Int64): Bool
    /*
     * The Function is read
     *
     * @param sink of Array<Byte>
     *
     * @return Type of Int64
     * @since 0.32.5
     */
    func read(sink: Array<Byte>): Int64
    /*
     * The Function is read
     *
     * @param sink of ByteBuffer
     *
     * @return Type of Int64
     * @since 0.32.5
     */
    func read(sink: ByteBuffer): Int64
    /*
     * The Function is read
     *
     * @param sink of Array<Byte>
     * @param offset of Int64
     * @param byteCount of Int64
     *
     * @return Type of Int64
     * @since 0.32.5
     */
    func read(sink: Array<Byte>, offset: Int64, byteCount: Int64): Int64


    /*
     * The Function is readInt8
     *
     * @return Type of Int8
     * @since 0.32.5
     */
    func readInt8(): Int8
    /*
     * The Function is readInt16
     *
     * @return Type of Int16
     * @since 0.32.5
     */
    func readInt16(): Int16
    /*
     * The Function is readInt16Le
     *
     * @return Type of Int16
     * @since 0.32.5
     */
    func readInt16Le(): Int16
    /*
     * The Function is readInt32
     *
     * @return Type of Int32
     * @since 0.32.5
     */
    func readInt32(): Int32
    /*
     * The Function is readInt32Le
     *
     * @return Type of Int32
     * @since 0.32.5
     */
    func readInt32Le(): Int32
    /*
     * The Function is readInt64
     *
     * @return Type of Int64
     * @since 0.32.5
     */
    func readInt64(): Int64
    /*
     * The Function is readInt64Le
     *
     * @return Type of Int64
     * @since 0.32.5
     */
    func readInt64Le(): Int64
    /*
     * The Function is readDecimalInt64
     *
     * @return Type of Int64
     * @since 0.32.5
     */
    func readDecimalInt64(): Int64
    /*
     * The Function is readHexadecimalUInt64
     *
     * @return Type of Int64
     * @since 0.32.5
     */
    func readHexadecimalUInt64(): Int64
    /*
     * The Function is readByteString
     *
     * @return Type of ByteString
     * @since 0.32.5
     */
    func readByteString(): ByteString
    /*
     * The Function is readByteString
     *
     * @param byteCount of Int64
     *
     * @return Type of ByteString
     * @since 0.32.5
     */
    func readByteString(byteCount: Int64): ByteString
    /*
     * The Function is readByteArray
     *
     * @return Type of Array<Byte>
     * @since 0.32.5
     */
    func readByteArray(): Array<Byte>
    /*
     * The Function is readByteArray
     *
     * @param byteCount of Int64
     *
     * @return Type of Array<Byte>
     * @since 0.32.5
     */
    func readByteArray(byteCount: Int64): Array<Byte>
    /*
     * The Function is readFully
     *
     * @param sink of Array<Byte>
     *
     * @return Type of Unit
     * @since 0.32.5
     */
    func readFully(sink: Array<Byte>): Unit
    /*
     * The Function is readFully
     *
     * @param sink of Buffer
     * @param byteCount of Int64
     *
     * @return Type of Unit
     * @since 0.32.5
     */
    func readFully(sink: Buffer, byteCount: Int64): Unit
    /*
     * The Function is readAll
     *
     * @param sink of Sink
     *
     * @return Type of Int64
     * @since 0.32.5
     */
    func readAll(sink: Sink): Int64
    /*
     * The Function is readUtf8
     *
     * @return Type of ?String
     * @since 0.32.5
     */
    func readUtf8(): String
    /*
     * The Function is readUtf8
     *
     * @param byteCount of Int64
     *
     * @return Type of ?String
     * @since 0.32.5
     */
    func readUtf8(byteCount: Int64): String
    /*
     * The Function is readString
     *
     * @return Type of ?String
     * @since 0.32.5
     */
    func readString(): String
    /*
     * The Function is readString
     *
     * @param byteCount of Int64
     *
     * @return Type of ?String
     * @since 0.32.5
     */
    func readString(byteCount: Int64): String
    /*
     * The Function is readUtf8Line
     *
     * @return Type of ?String
     * @since 0.32.5
     */
    func readUtf8Line(): ?String
    /*
     * The Function is readUtf8LineStrict
     *
     * @return Type of ?String
     * @since 0.32.5
     */
    func readUtf8LineStrict(): ?String
    /*
     * The Function is readUtf8LineStrict
     *
     * @param limit of Int64
     *
     * @return Type of ?String
     * @since 0.32.5
     */
    func readUtf8LineStrict(limit: Int64): ?String
    /*
     * The Function is readUtf8CodePoint
     *
     * @return Type of Int64
     * @since 0.32.5
     */
    func readUtf8CodePoint(): Int64
    /*
     * The Function is indexOf
     *
     * @param value of Int8
     *
     * @return Type of Int64
     * @since 0.32.5
     */
    func indexOf(value: Int8): Int64
    /*
     * The Function is indexOf
     *
     * @param value of Int8
     * @param fromIndex of Int64
     *
     * @return Type of Int64
     * @since 0.32.5
     */
    func indexOf(value: Int8, fromIndex: Int64): Int64
    /*
     * The Function is indexOf
     *
     * @param value of Int8
     * @param fromIndex of Int64
     * @param toIndex of Int64
     *
     * @return Type of Int64
     * @since 0.32.5
     */
    func indexOf(value: Int8, fromIndex: Int64, toIndex: Int64): Int64
    /*
     * The Function is indexOf
     *
     * @param bytes of ByteString
     *
     * @return Type of Int64
     * @since 0.32.5
     */
    func indexOf(bytes: ByteString): Int64
    /*
     * The Function is indexOf
     *
     * @param bytes of ByteString
     * @param fromIndex of Int64
     *
     * @return Type of Int64
     * @since 0.32.5
     */
    func indexOf(bytes: ByteString, fromIndex: Int64): Int64
    /*
     * The Function is indexOfElement
     *
     * @param targetBytes of ByteString
     *
     * @return Type of Int64
     * @since 0.32.5
     */
    func indexOfElement(targetBytes: ByteString): Int64
    /*
     * The Function is indexOfElement
     *
     * @param targetBytes of ByteString
     * @param fromIndex of Int64
     *
     * @return Type of Int64
     * @since 0.32.5
     */
    func indexOfElement(targetBytes: ByteString, fromIndex: Int64): Int64
    /*
     * The Function is rangeEquals
     *
     * @param offset of Int64
     * @param bytes of ByteString
     *
     * @return Type of Bool
     * @since 0.32.5
     */
    func rangeEquals(offset: Int64, bytes: ByteString): Bool
    /*
     * The Function is rangeEquals
     *
     * @param offset of Int64
     * @param bytes of ByteString
     * @param bytesOffset of Int64
     * @param byteCount of Int64
     *
     * @return Type of Bool
     * @since 0.32.5
     */
    func rangeEquals(offset: Int64, bytes: ByteString, bytesOffset: Int64, byteCount: Int64): Bool
    /*
     * The Function is skip
     *
     * @param byteCount of Int64
     *
     * @return Type of Unit
     * @since 0.32.5
     */
    func skip(byteCount: Int64): Unit
    /*
     * The Function is peek
     *
     * @return Type of BufferedSource
     * @since 0.32.5
     */
    func peek(): BufferedSource
}
