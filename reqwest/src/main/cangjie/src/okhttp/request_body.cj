/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2022-2024. All rights resvered.
 */

/**
 * @file
 * The file declars the RequestBody interface.
 */

package ohos_app_cangjie_reqwest.okhttp

/**
 * The class is RealRequestBody
 * @author guo_tingtingtekla,luoyukai4
 * @since 0.29.3
 */
public class RealRequestBody <: RequestBody {
    /* var member content type is Array<Byte>*/
    private let bytes: Array<Byte>

    /* var member MediaType type is String */
    private var mediaType: Option<MediaType>
    private let contentLength: Int64

    /*
     * The Function is init constructor
     *
     * @param MediaType of String
     * @param content of String
     * @since 0.29.3
     */
    init(mediaType: Option<MediaType>, bytes: Array<Byte>) {
        contentLength = bytes.size
        this.bytes = bytes
        this.mediaType = mediaType
    }

    /**
     * The Function is contentType
     *
     * @return Type of String
     * @since 0.29.3
     */
    public func contentType(): Option<MediaType> {
        return mediaType
    }

    /**
     * The Function is contentLength
     *
     * @return Type of Int64
     * @since 0.29.3
     */
    public func getContentLength(): Int64 {
        return contentLength
    }

    public func writeTo(sink: Sink): Unit {
        sink.write(bytes)
    }

    /**
     * The Function is get
     *
     * @return Type of ReadCloseStream
     * @since 0.29.3
     */
    public func get(): InputStream {
        let arr = ByteArrayStream()
        arr.write(bytes)
        return arr
    }

    public static func create(contentType: Option<MediaType>, content: String): RequestBody {
        return create(contentType, content.toUtf8Array())
    }

    public static func create(contentType: Option<MediaType>, bytes: Array<Byte>): RequestBody {
        return RealRequestBody(contentType, bytes)
    }

    public static func create(contentType: Option<MediaType>, file: File): RequestBody {
        return create(contentType, file.readToEnd())
    }
}
