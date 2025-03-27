/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2022-2024. All rights resvered.
 */

package ohos_app_cangjie_OkRequest.okhttp
import ohos_app_cangjie_OkRequest.okio.*
import ohos.hilog.Hilog

/**
 * @file The file manage Http2Writer.
 */
let INITIAL_MAX_FRAME_SIZE = 0x4000 //16384
let TYPE_DATA: Byte = 0x0
let TYPE_HEADERS: Byte = 0x1
let TYPE_PRIORITY: Byte = 0x2
let TYPE_RST_STREAM: Byte = 0x3
let TYPE_SETTINGS: Byte = 0x4
let TYPE_PUSH_PROMISE: Byte = 0x5
let TYPE_PING: Byte = 0x6
let TYPE_GOAWAY: Byte = 0x7
let TYPE_WINDOW_UPDATE: Byte = 0x8
let TYPE_CONTINUATION: Byte = 0x9
let FLAG_NONE: Byte = 0x0
let FLAG_ACK: Byte = 0x1
let FLAG_END_STREAM: Byte = 0x1
let FLAG_END_HEADERS: Byte = 0x4
let FLAG_END_PUSH_PROMISE: Byte = 0x4
let FLAG_PADDED: Byte = 0x8
let FLAG_PRIORITY: Byte = 0x20
let FLAG_COMPRESSED: Byte = 0x20

/*
 * The class is Http2Writer
 *
 * Writes HTTP/2 transport frames
 *
 * @author luoyukai4
 * @since 0.34.3
 */
class Http2Writer {
    private let sink: BufferedSink
    let mutex: Monitor = Monitor()
    private var closed: Bool = false
    private var maxFrameSize = INITIAL_MAX_FRAME_SIZE
    private let encoder: Encoder

    init(sink: BufferedSink, encoder: Encoder) {
        this.sink = sink
        this.encoder = encoder
    }

    func connectionPreface(): Unit {
        synchronized(mutex) {
            if (closed) {
                throw HttpException("closed")
            }

            sink.write(PREFACE.toUtf8Array())
            sink.flush()
        }
    }

    func settings(settings: Settings): Unit {
        synchronized(mutex) {
            if (closed) {
                throw HttpException("closed")
            }

            let length = settings.size() * 6
            let frameType: Byte = TYPE_SETTINGS
            let flags: Byte = FLAG_NONE
            var streamId: UInt32 = 0

            frameHeader(streamId, length, frameType, flags)

            for (i in 0..Settings.COUNT) {
                if (!settings.isSet(i)) {
                    continue
                }
                var id = i
                if (id == 4) {
                    id = 3 // SETTINGS_MAX_CONCURRENT_STREAMS renumbered.
                } else if (id == 7) {
                    id = 4 // SETTINGS_INITIAL_WINDOW_SIZE renumbered.
                }

                writeUInt16(sink, id)
                writeUInt32(sink, settings.get(i))
            }

            sink.flush()
        }
    }

    func flush() {
        synchronized(mutex) {
            if (closed) {
                throw HttpException("closed")
            }
            sink.flush()
        }
    }

    func windowUpdate(streamId: UInt32, windowSizeIncrement: Int64) {
        synchronized(mutex) {
            if (closed) {
                throw HttpException("closed")
            }

            if (windowSizeIncrement == 0 || windowSizeIncrement > 0x7fffffff) {
                throw IllegalArgumentException(
                    "windowSizeIncrement == 0 || windowSizeIncrement > 0x7fffffff: ${windowSizeIncrement}")
            }

            let length = 4
            let frameType: Byte = TYPE_WINDOW_UPDATE
            let flags: Byte = FLAG_NONE
            frameHeader(streamId, length, frameType, flags)
            writeUInt32(sink, windowSizeIncrement)
            sink.flush()
        }
    }

    func frameHeader(streamId: UInt32, length: Int64, frameType: Byte, flags: Byte): Unit {
        if (length > maxFrameSize) {
            throw IllegalArgumentException("FRAME_SIZE_ERROR length ${length} > ${maxFrameSize}")
        }

        if ((streamId & 0x80000000) != 0) {
            throw IllegalArgumentException("reserved bit set : ${streamId}")
        }

        writeMedium(sink, length)
        writeByte(sink, frameType & 0xff)
        writeByte(sink, flags & 0xff)
        writeUInt32(sink, Int64(streamId) & 0x7fffffff)
    }

    private func writeMedium(sink: BufferedSink, b: Int64): Unit {
        let i = UInt32(b)
        let arr: Array<Byte> = [UInt8((i >> 16) & 0xff), UInt8((i >> 8) & 0xff), UInt8(i & 0xff)]
        sink.write(arr)
    }

    private func writeByte(sink: BufferedSink, b: Byte) {
        sink.write([b])
    }

    private func writeUInt32(sink: BufferedSink, i: Int64) {
        let b = UInt32(i)
        let arr: Array<Byte> = [
            UInt8((b >> 24) & 0xff),
            UInt8((b >> 16) & 0xff),
            UInt8((b >> 8) & 0xff),
            UInt8(b & 0xff)
        ]
        sink.write(arr)
    }

    private func writeUInt16(sink: BufferedSink, i: Int64) {
        let b = UInt32(i)
        let arr: Array<Byte> = [UInt8((b >> 8) & 0xff), UInt8(b & 0xff)]
        sink.write(arr)
    }

    func rstStream(streamId: UInt32, errorCode: ErrorCode) {
        synchronized(mutex) {
            if (closed) {
                throw HttpException("closed")
            }

            let length = 4
            let frameType = TYPE_RST_STREAM
            let flags = FLAG_NONE
            frameHeader(streamId, length, frameType, flags)
            writeUInt32(sink, errorCode.getCode())
            sink.flush()
        }
    }

    func goAway(lastGoodStreamId: UInt32, errorCode: ErrorCode, debugData: Array<Byte>) {
        synchronized(mutex) {
            if (closed) {
                throw HttpException("closed")
            }
            let length = 8 + debugData.size
            let frameType = TYPE_GOAWAY
            let flags = FLAG_NONE
            let streamId: UInt32 = 0
            frameHeader(streamId, length, frameType, flags)
            writeUInt32(sink, Int64(lastGoodStreamId))
            writeUInt32(sink, errorCode.getCode())
            if (debugData.size > 0) {
                sink.write(debugData)
            }
            sink.flush()
        }
    }

    func headers(outFinished: Bool, streamId: UInt32, headerBlock: ArrayList<HeaderField>) {
        synchronized(mutex) {
            if (closed) {
                throw HttpException("closed")
            }
            let hpackBuffer: Array<UInt8> = encoder.encode(headerBlock)
            let byteCount = hpackBuffer.size
            let length = min(maxFrameSize, byteCount)
            let frameType = TYPE_HEADERS
            var flags: Byte = FLAG_NONE
            if (byteCount == length) {
                flags = FLAG_END_HEADERS
            }

            if (outFinished) {
                flags |= FLAG_END_STREAM
            }

            frameHeader(streamId, length, frameType, flags)
            sink.write(hpackBuffer[0..length])

            if (byteCount > length) {
                writeContinuationFrames(streamId, byteCount - length, hpackBuffer[length..hpackBuffer.size])
            }
        }
    }

    private func writeContinuationFrames(streamId: UInt32, continueCount: Int64, hpackBuffer: Array<UInt8>) {
        var byteCount = continueCount
        while (byteCount > 0) {
            let length = min(maxFrameSize, byteCount)
            byteCount -= length
            var flags: Byte = 0x0
            if (byteCount == 0) {
                flags = FLAG_END_HEADERS
            }
            frameHeader(streamId, length, TYPE_CONTINUATION, flags)
            sink.write(hpackBuffer)
        }
    }

    func maxDataLength(): Int64 {
        return maxFrameSize
    }

    func applyAndAckSettings(peerSettings: Settings) {
        synchronized(mutex) {
            if (closed) {
                throw HttpException("closed")
            }

            this.maxFrameSize = peerSettings.getMaxFrameSize(maxFrameSize)

            if (peerSettings.getHeaderTableSize() != -1) {
                encoder.updateMaxSize(UInt32(peerSettings.getHeaderTableSize()))
            }

            let length = 0
            let frameType: Byte = TYPE_SETTINGS
            let flags: Byte = FLAG_ACK
            let streamId: UInt32 = 0
            frameHeader(streamId, length, frameType, flags)
            sink.flush()
        }
    }

    func ping(reply: Bool, payload1: Int64, payload2: Int64) {
        synchronized(mutex) {
            if (closed) {
                throw HttpException("closed")
            }

            let length = 8
            let frameType: Byte = TYPE_PING
            let flags: Byte
            if (reply) {
                flags = FLAG_ACK
            } else {
                flags = FLAG_NONE
            }
            let streamId: UInt32 = 0
            frameHeader(streamId, length, frameType, flags)
            writeUInt32(sink, payload1)
            writeUInt32(sink, payload2)
            sink.flush()
        }
    }

    func data(outFinished: Bool, streamId: UInt32, source: Buffer, byteCount: Int64) {
        synchronized(mutex) {
            if (closed) {
                throw HttpException("closed")
            }
            var flags: Byte = FLAG_NONE

            if (outFinished) {
                flags |= FLAG_END_STREAM
            }
            dataFrame(streamId, flags, source, byteCount)
        }
    }

    func dataFrame(streamId: UInt32, flags: Byte, source: Buffer, byteCount: Int64) {
        let frameType = TYPE_DATA
        frameHeader(streamId, byteCount, frameType, flags)
        if (byteCount > 0) {
            let arr = Array<Byte>(byteCount, item: 0)
            source.read(arr)
            sink.write(arr)
        }
    }

    func close() {
        synchronized(mutex) {
            closed = true
        }
    }
}
