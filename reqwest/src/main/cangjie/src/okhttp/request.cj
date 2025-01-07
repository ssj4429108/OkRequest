/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2022-2024. All rights resvered.
 */

/**
 * @file
 * The file declares the Request class.
 */

package ohos_app_cangjie_OkRequest.okhttp

/**
 * The class is Request
 * @author guo_tingtingtekla,luoyukai4
 * @since 0.29.3
 */
public class Request <: ToString {
    /* var member url type is URL */
    var url: URL

    /* var member header type is Header */
    var header: Header

    /* var member method type is String */
    var method: String

    /* var member body type is Option<RequestBody> */
    var body: Option<RequestBody>

    private var cacheControl: Option<CacheControl> = Option<CacheControl>.None

    let tags: HashMap<String, Tag>

    /**
     * The Function is init constructor
     *
     * @param builder of RequestBuilder
     * @since 0.29.3
     */
    public init(builder: RequestBuilder) {
        this.url = builder.urlBuild
        this.header = builder.headerBuild.clone()
        this.method = builder.methodBuild
        this.body = builder.bodyBuild
        this.tags = builder.tagsBuild
    }

    /**
     * The Function is getUrl
     *
     * @return Type of URL
     * @since 0.29.3
     */
    public func getUrl(): URL {
        return url
    }

    /**
     * The Function is getMethod
     *
     * @return Type of String
     * @since 0.29.3
     */
    public func getMethod(): String {
        return method
    }

    /**
     * The Function is getBody
     *
     * @return Type of Option<RequestBody>
     * @since 0.29.3
     */
    public func getBody(): Option<RequestBody> {
        return body
    }

    /**
     * The Function is builder
     *
     * @return Type of RequestBuilder
     * @since 0.29.3
     */
    public static func builder(): RequestBuilder {
        return RequestBuilder()
    }

    /**
     * The Function is newBuilder
     *
     * @return Type of RequestBuilder
     * @since 0.29.3
     */
    public func newBuilder(): RequestBuilder {
        return RequestBuilder(this)
    }

    /**
     * The Function is getHeaders
     *
     * @return Type of Header
     * @since 0.29.3
     */
    public func getHeaders(): Header {
        return header
    }

    /**
     * The Function is getHeader
     *
     * @param name of String
     *
     * @return Type of String
     * @since 0.29.3
     */
    public func getHeader(name: String): Option<String> {
        return header.getString(name)
    }

    /**
     * The Function is getHeader
     *
     * @param name of String
     * @param defaultValue of String
     *
     * @return Type of String
     * @since 0.29.3
     */
    public func getHeader(name: String, defaultValue: String): String {
        return header.getString(name) ?? defaultValue
    }

    public func toString(): String {
        return "Request{method= ${method}, url= ${url.toString()}}"
    }

    /**
     * Returns the cache control directives for this response. This is never null, even if this
     * response contains no {@code Cache-Control} header.
     *
     * @since 0.30.4
     */
    public func getCacheControl(): CacheControl {
        match (cacheControl) {
            case Some(b) => return b
            case None =>
                let cacheControl = CacheControl.parse(header)
                this.cacheControl = cacheControl
                return cacheControl
        }
    }

    public func getTag(s: String): Tag {
        if (tags.contains(s)) {
            return tags[s]
        } else {
            return Tag("")
        }
    }

    public func removeTag(s: String): Unit {
        this.tags.remove(s)
    }
}

public class Tag {
    public var tag: String

    public init(tag: String) {
        this.tag = tag
    }
}
