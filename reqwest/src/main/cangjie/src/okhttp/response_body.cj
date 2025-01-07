/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2022-2024. All rights resvered.
 */

/**
 * @file
 * The file declares the ResponseBody class.
 */

package ohos_app_cangjie_OkRequest.okhttp

/**
 * The class is ResponseBody
 * @author guo_tingtingtekla,luoyukai4
 * @since 0.29.3
 */
public open class ResponseBody <: Resource {
    /* var member source type is StringStream */
    var source: Source

    /* var member contentType type is String */
    var contentTypeString: String

    /* var member contentLength type is Int64 */
    var contentLength: Int64 = 0

    /**
     * The Function is init constructor
     *
     * @param contentType of String
     * @param contentLength of Int64
     * @param source of StringStream
     * @since 0.29.3
     */
    public init(contentType: String, contentLength: Int64, source: Source) {
        this.source = source
        this.contentTypeString = contentType
        this.contentLength = contentLength
    }

    /**
     * The Function is getSource
     *
     * @return Type of StringStream
     * @since 0.29.3
     */
    public func getSource(): Source {
        return source
    }

    public func getContentType(): Option<MediaType> {
        if (contentTypeString == "") {
            return Option<MediaType>.None
        } else {
            return MediaType.parse(contentTypeString)
        }
    }

    /**
     * The Function is close
     *
     * @return Type of Unit
     * @since 0.29.3
     */
    public func close(): Unit {
        Util.closeQuietly(source)
    }

    public func isClosed(): Bool {
        return source.isClosed()
    }

    public func getContentLength(): Int64 {
        return contentLength
    }

    public func getString(): String {
        let stream = ByteArrayStream()
        try (r = source) {
            while (source.read(stream, 4096) > 0) {}
        } catch (e: EOFException) {}
        return String.fromUtf8(stream.readToEnd())
    }

    public func getBytes(): Array<Byte> {
        let stream = ByteArrayStream()
        try (r = source) {
            while (source.read(stream, 4096) > 0) {}
        } catch (e: EOFException) {}
        return stream.readToEnd()
    }
}
