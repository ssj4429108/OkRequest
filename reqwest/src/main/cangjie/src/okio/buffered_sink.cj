/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2022-2024. All rights resvered.
 */

/**
 * @file
 * The file declars the BufferedSink interface.
 */

package ohos_app_cangjie_OkRequest.okio

/**
 * The interface is BufferedSink inherited from Sink & ToString
 * @author liyanqing14
 * @since 0.32.5
 */
public interface BufferedSink <: Sink & ToString {
    /*
     * The Function is buffer
     *
     * @return Type of Buffer
     * @since 0.32.5
     */
    func buffer(): Buffer
    /*
     * The Function is write
     *
     * @param byteString of ByteString
     *
     * @return Type of BufferedSink
     * @since 0.32.5
     */
    func write(byteString: ByteString): BufferedSink
    /*
     * The Function is write
     *
     * @param source of Array<Byte>
     *
     * @return Type of BufferedSink
     * @since 0.32.5
     */
    func write(source: Array<Byte>): BufferedSink
    /*
     * The Function is write
     *
     * @param source of Array<Byte>
     * @param offset of Int64
     * @param byteCount of Int64
     *
     * @return Type of BufferedSink
     * @since 0.32.5
     */
    func write(source: Array<Byte>, offset: Int64, byteCount: Int64): BufferedSink
    // func write(source: Buffer): BufferedSink
    /*
     * The Function is write
     *
     * @param source of Source
     * @param byteCount of Int64
     *
     * @return Type of BufferedSink
     * @since 0.32.5
     */
    func write(source: Source, byteCount: Int64): BufferedSink
    // func write(source: Buffer, byteCount: Int64): Unit
    /*
     * The Function is writeAll
     *
     * @param source of Source
     *
     * @return Type of Int64
     * @since 0.32.5
     */
    func writeAll(source: Source): Int64
    /*
     * The Function is writeUtf8
     *
     * @param string of String
     *
     * @return Type of BufferedSink
     * @since 0.32.5
     */
    func writeUtf8(string: String): BufferedSink
    /*
     * The Function is writeUtf8
     *
     * @param string of String
     * @param beginIndex of Int64
     * @param endIndex of Int64
     *
     * @return Type of BufferedSink
     * @since 0.32.5
     */
    func writeUtf8(string: String, beginIndex: Int64, endIndex: Int64): BufferedSink
    /*
     * The Function is writeUtf8CodePoint
     *
     * @param codePoInt64 of Int64
     *
     * @return Type of BufferedSink
     * @since 0.32.5
     */
    func writeUtf8CodePoint(codePoInt64: Int64): BufferedSink
    // func writeString(string: String, charset: Charset): BufferedSink
    // func writeString(string: String, beginIndex: Int64, endIndex: Int64, charset: Charset): BufferedSink
    /*
     * The Function is writeInt8
     *
     * @param value of Int64
     *
     * @return Type of BufferedSink
     * @since 0.32.5
     */
    func writeInt8(value: Int64): BufferedSink
    /*
     * The Function is writeInt16
     *
     * @param value of Int64
     *
     * @return Type of BufferedSink
     * @since 0.32.5
     */
    func writeInt16(value: Int64): BufferedSink
    /*
     * The Function is writeInt16Le
     *
     * @param value of Int64
     *
     * @return Type of BufferedSink
     * @since 0.32.5
     */
    func writeInt16Le(value: Int64): BufferedSink
    /*
     * The Function is writeInt32
     *
     * @param value of Int64
     *
     * @return Type of BufferedSink
     * @since 0.32.5
     */
    func writeInt32(value: Int64): BufferedSink
    /*
     * The Function is writeInt32Le
     *
     * @param value of Int64
     *
     * @return Type of BufferedSink
     * @since 0.32.5
     */
    func writeInt32Le(value: Int64): BufferedSink
    /*
     * The Function is writeInt64
     *
     * @param value of Int64
     *
     * @return Type of BufferedSink
     * @since 0.32.5
     */
    func writeInt64(value: Int64): BufferedSink
    /*
     * The Function is writeInt64Le
     *
     * @param value of Int64
     *
     * @return Type of BufferedSink
     * @since 0.32.5
     */
    func writeInt64Le(value: Int64): BufferedSink
    /*
     * The Function is emit
     *
     * @return Type of BufferedSink
     * @since 0.32.5
     */
    func emit(): BufferedSink
    /*
     * The Function is emitCompleteSegments
     *
     * @return Type of BufferedSink
     * @since 0.32.5
     */
    func emitCompleteSegments(): BufferedSink
    // func outputStream(): OutputStream
}
