/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2022-2024. All rights resvered.
 */

package ohos_app_cangjie_OkRequest.okhttp
import ohos_app_cangjie_OkRequest.okio.*
/**
 * @file The file manage Http2Reader.
 */

/*
 * The class is Http2Reader
 * Reads HTTP/2 transport frames
 *
 * @author luoyukai4
 * @since 0.34.3
 */
class Http2Reader {
    let source: BufferedSource
    let frameDecode = Decoder.newDecode()

    init(source: BufferedSource) {
        this.source = source
    }

    func readConnectionPreface(handler: H2Connection) {
        if (!nextFrame(true, handler)) {
            throw HttpException("Required SETTINGS preface not received")
        }
    }

    func nextFrame(requireSettings: Bool, handler: H2Connection): Bool {
        try {
            let length = readMedium(source)
            if (length < 0 || length > INITIAL_MAX_FRAME_SIZE) {
                throw HttpException("FRAME_SIZE_ERROR: ${length}")
            }
            let frameType: Byte = UInt8(source.readInt8())

            if (requireSettings && frameType != TYPE_SETTINGS) {
                throw HttpException("Expected a SETTINGS frame but was ${frameType}")
            }

            let flags: Byte = UInt8(source.readInt8())
            let streamId: UInt32 = UInt32(readInt32(source) & 0x7fffffff)
            match (frameType) {
                case 0x0 => //DATA
                    readData(handler, length, flags, streamId)
                case 0x1 => //HEADER
                    readHeaders(handler, length, flags, streamId)
                case 0x3 => //TYPE_RST_STREAM
                    readRstStream(handler, length, flags, streamId)
                case 0x4 => //SETTINGS
                    readSettings(handler, length, flags, streamId)
                case 0x6 => //PING
                    readPing(handler, length, flags, streamId)
                case 0x7 => //GOAWAY
                    readGoAway(handler, length, flags, streamId)
                case 0x8 => //TYPE_WINDOW_UPDATE
                    readWindowUpdate(handler, length, flags, streamId)
                case _ => source.skip(length)
            }
            return true
        } catch (e: EOFException) {
            return false
        } catch (e: SocketException) {
            throw HttpException("SocketException")
        } catch (e: Exception) {
            e.printStackTrace()
            throw e
        }
    }

    private func readInt32(source: BufferedSource): Int64 {
        return Int64(Int32(source.readInt8()) << 24 | Int32(source.readInt8()) << 16 | Int32(source.readInt8()) << 8 |
                Int32(source.readInt8()))
    }

    private func readInt16(source: BufferedSource): Int64 {
        return Int64(Int32(source.readInt8()) << 8 | Int32(source.readInt8()))
    }

    func readMedium(source: BufferedSource): Int64 {
        return Int64(Int32(source.readInt8()) << 16 | Int32(source.readInt8()) << 8 | Int32(source.readInt8()))
    }

    func lengthWithoutPadding(len: Int64, flags: Byte, padding: Int64) {
        var length = len

        if ((flags & FLAG_PADDED) != 0) {
            length--
        }

        if (padding > length) {
            throw HttpException("PROTOCOL_ERROR padding ${padding} > remaining length ${length}")
        }

        return length - padding
    }

    func readPriority(_: UInt32) {
        readInt32(source)
        source.readInt8()
    }

    private func readWindowUpdate(handler: H2Connection, length: Int64, _: Byte, streamId: UInt32) {
        if (length != 4) {
            throw HttpException("TYPE_WINDOW_UPDATE length !=4: ${length}")
        }

        let increment = readInt32(source) & 0x7fffffff

        if (increment == 0) {
            throw HttpException("windowSizeIncrement was 0")
        }

        handler.windowUpdate(streamId, increment)
    }

    private func readRstStream(handler: H2Connection, length: Int64, _: Byte, streamId: UInt32) {
        if (length != 4) {
            throw HttpException("TYPE_RST_STREAM length !=4: ${length}")
        }

        if (streamId == 0) {
            throw HttpException("TYPE_RST_STREAM streamId == 0")
        }

        let errorCodeInt = readInt32(source)
        let errorCode = ErrorCode.fromHttp2(errorCodeInt)
        if (!has(errorCode)) {
            throw HttpException("TYPE_RST_STREAM unexpected error code: ${errorCodeInt}")
        }
        handler.rstStream(streamId, errorCode.getOrThrow())
    }

    private func readGoAway(handler: H2Connection, length: Int64, _: Byte, streamId: UInt32) {
        if (length < 8) {
            throw HttpException("TYPE_GOAWAY length < 8: ${length}")
        }

        if (streamId != 0) {
            throw HttpException("TYPE_GOAWAY streamId != 0")
        }

        let lastStreamId = readInt32(source)
        let errorCodeInt = readInt32(source)
        let opaqueDataLength = length - 8
        let errorCode = ErrorCode.fromHttp2(errorCodeInt)

        if (!has(errorCode)) {
            throw HttpException("TYPE_GOAWAY unexpected error code: ${errorCodeInt}")
        }
        // var debugData = ByteString()
        // if (opaqueDataLength > 0) {
        //     debugData = source.readByteString(opaqueDataLength)
        // }

        handler.goAway(lastStreamId, errorCode.getOrThrow())
    }

    private func readHeaders(handler: H2Connection, len: Int64, flags: Byte, streamId: UInt32) {
        if (streamId == 0) {
            throw HttpException("TYPE_HEADERS streamId == 0")
        }

        var length = len
        var endStream: Bool = (flags & FLAG_END_STREAM) != 0
        var padding = 0

        if ((flags & FLAG_PADDED) != 0) {
            padding = Int64(source.readInt8())
        }

        if ((flags & FLAG_PRIORITY) != 0) {
            readPriority(streamId)
            length -= 5
            // account for above read.
        }

        length = lengthWithoutPadding(length, flags, padding)
        // let arr = ByteArrayStream()
        let arr = Array<Byte>(length, item: 0)
        source.read(arr)
        source.skip(padding)

        while (endStream) {
            endStream = readContinuationHeader(arr, streamId)
        }

        let headerBlock: Array<HeaderField> = frameDecode.decode(arr)
        handler.headers(endStream, streamId, -1, headerBlock)
    }

    

    func readContinuationHeader(arr: Array<Byte>, previousStreamId: UInt32) {
        let length = readMedium(source)
        let frameType: Byte = UInt8(source.readInt8())
        let flags: Byte = UInt8(source.readInt8())
        let streamId: UInt32 = UInt32(readInt32(source) & 0x7fffffff)

        if (frameType != TYPE_CONTINUATION) {
            throw HttpException("${frameType} != TYPE_CONTINUATION")
        }

        if (previousStreamId != streamId) {
            throw HttpException("TYPE_CONTINUATION streamId changed")
        }

        source.read(arr, 0, length)
        return (flags & FLAG_END_STREAM) != 0
    }

    private func readData(handler: H2Connection, len: Int64, flags: Byte, streamId: UInt32) {
        if (streamId == 0) {
            throw HttpException("TYPE_DATA streamId == 0")
        }

        let inFinished: Bool = (flags & FLAG_END_STREAM) != 0
        let gzipped: Bool = (flags & FLAG_COMPRESSED) != 0

        if (gzipped) {
            throw HttpException("PROTOCOL_ERROR: FLAG_COMPRESSED without SETTINGS_COMPRESS_DATA")
        }

        var padding = 0
        if ((flags & FLAG_PADDED) != 0) {
            padding = Int64(source.readInt8())
        }

        let length = lengthWithoutPadding(len, flags, padding)
        handler.data(inFinished, streamId, source, length)
        source.skip(padding)
    }

    private func readPing(handler: H2Connection, length: Int64, flags: Byte, streamId: UInt32) {
        if (length != 8) {
            throw HttpException("TYPE_PING length != 8: ${length}")
        }

        if (streamId != 0) {
            throw HttpException("TYPE_PING streamId != 0")
        }

        let payload1 = readInt32(source)
        let payload2 = readInt32(source)
        let ack: Bool = (flags & FLAG_ACK) != 0
        handler.ping(ack, payload1, payload2)
    }

    private func readSettings(handler: H2Connection, length: Int64, flags: Byte, streamId: UInt32) {
        if (streamId != 0) {
            throw HttpException("TYPE_SETTINGS streamId != 0")
        }

        if ((flags & FLAG_ACK) != 0) {
            if (length != 0) {
                throw HttpException("FRAME_SIZE_ERROR ack frame should be empty!")
            }
            return
        }

        if (length % 6 != 0) {
            throw HttpException("TYPE_SETTINGS length %% 6 != 0: ${length}")
        }

        let settings: Settings = Settings()

        for (_ in 0..length : 6) {
            var id = readInt16(source) & 0xFFFF
            let value = Int32(readInt32(source))
            match (id) {
                case 1 => // SETTINGS_HEADER_TABLE_SIZE
                ()
                case 2 =>
                        // SETTINGS_ENABLE_PUSH
                        if (value != 0 && value != 1) {
                    throw HttpException("PROTOCOL_ERROR SETTINGS_ENABLE_PUSH != 0 or 1")
                }
                case 3 => // SETTINGS_MAX_CONCURRENT_STREAMS
                id = 4 // Renumbered in draft 10
                case 4 =>
                    // SETTINGS_INITIAL_WINDOW_SIZE
                    id = 7 // Renumbered in draft 10
                    if (value < 0) {
                        throw HttpException("PROTOCOL_ERROR SETTINGS_INITIAL_WINDOW_SIZE should < 2^31 - 1")
                    }
                case 5 => if (Int64(value) < INITIAL_MAX_FRAME_SIZE || value > 16777215) {
                    throw HttpException("PROTOCOL_ERROR SETTINGS_MAX_FRAME_SIZE: ${value}")
                }
                case 6 => // SETTINGS_MAX_HEADER_LIST_SIZE
                ()
                case _ => // Must ignore setting with unknown id
                ()
            }
            settings.setting(id, Int64(value))
        }
        handler.settings(settings)
    }
}
