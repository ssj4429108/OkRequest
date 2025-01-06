/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2022-2024. All rights resvered.
 */

/**
 * @file
 * The file declares the RequestBuilder class.
 */

package ohos_app_cangjie_reqwest.okhttp

/**
 * The class is RequestBuilder inherited from Builder<Request>
 * @author guo_tingtingtekla,luoyukai4
 * @since 0.29.3
 */
public class RequestBuilder <: Builder<Request> {
    /** var member urlBuild type is URL */
    var urlBuild: URL = URL.parse("")

    /** var member headerBuild type is Header */
    var headerBuild: Header = Header()

    /** var member methodBuild type is String */
    var methodBuild: String = "GET"

    /** var member bodyBuild type is Option<RequestBody> */
    var bodyBuild: Option<RequestBody> = Option<RequestBody>.None
    var tagsBuild: HashMap<String, Tag> = HashMap<String, Tag>()

    /**
     * The Function is init constructor
     *
     * @param request of Request
     * @since 0.29.3
     */
    init(request: Request) {
        this.urlBuild = request.getUrl()
        this.methodBuild = request.getMethod()
        this.bodyBuild = request.getBody()
        this.headerBuild = request.getHeaders().clone()
        this.tagsBuild = HashMap<String, Tag>(request.tags)
    }

    /**
     * The Function is init constructor
     *
     * @since 0.29.3
     */
    init() {}

    /**
     * The Function is url
     *
     * @param url of String
     *
     * @return Type of RequestBuilder
     * @since 0.29.3
     */
    public func url(url: String): RequestBuilder {
        this.urlBuild = URL.parse(url)
        return this
    }

    /**
     * The Function is url
     *
     * @param url of URL
     *
     * @return Type of RequestBuilder
     * @since 0.29.3
     */
    public func url(url: URL): RequestBuilder {
        this.urlBuild = url
        return this
    }

    /**
     * The Function is header
     *
     * @param name of String
     * @param value of String
     *
     * @return Type of RequestBuilder
     * @since 0.29.3
     */
    public func header(name: String, value: Array<String>): RequestBuilder {
        headerBuild.set(name, ArrayList(value))
        return this
    }

    /**
     * The Function is method
     *
     * @param method of String
     *
     * @return Type of RequestBuilder
     * @since 0.29.3
     */
    public func method(method: String, body!: Option<RequestBody> = Option<RequestBody>.None): RequestBuilder {
        if (method.isEmpty()) {
            throw IllegalArgumentException("method length == 0")
        }

        match (body) {
            case Some(_) => if (!permitsRequestBody(method)) {
                throw IllegalArgumentException("method ${method} must not have a request body.")
            }
//            case None => if (requiresRequestBody(method)) {
//                throw IllegalArgumentException("method ${method} must have a request body.")
//            }
            case None => ()
        }
        this.methodBuild = method
        this.bodyBuild = body
        return this
    }

    /**
     * The Function is put
     *
     * @return Type of Request
     * @since 0.33.3
     */
    public func put(body: RequestBody): RequestBuilder {
        return method("PUT", body: body)
    }

    /**
     * The Function is put
     *
     * @return Type of Request
     * @since 0.33.3
     */
    public func post(body: RequestBody): RequestBuilder {
        return method("POST", body: body)
    }

    /**
     * The Function is patch
     *
     * @return Type of Request
     * @since 0.33.3
     */
    public func patch(body: RequestBody): RequestBuilder {
        return method("PATCH", body: body)
    }

    /**
     * The Function is patch
     *
     * @return Type of Request
     * @since 0.33.3
     */
    public func delete(body: Option<RequestBody>): RequestBuilder {
        return method("DELETE", body: body)
    }

    /**
     * The Function is get
     *
     * @return Type of Request
     * @since 0.33.3
     */
    public func get(): RequestBuilder {
        return method("GET")
    }

    /**
     * The Function is head
     *
     * @return Type of Request
     * @since 0.33.3
     */
    public func head(): RequestBuilder {
        return method("HEAD")
    }

    /**
     * The Function is build
     *
     * @return Type of Request
     * @since 0.29.3
     */
    public func build(): Request {
        return Request(this)
    }

    /**
     * The Function is removeHeader
     *
     * @param name of String
     *
     * @return Type of Unit
     * @since 0.29.3
     */
    public func removeHeader(name: String): RequestBuilder {
        headerBuild.remove(name)
        return this
    }

    /**
     * The Function is header
     *
     * @param header of Header
     * @since 0.29.3
     */
    public func header(header: Header): RequestBuilder {
        this.headerBuild = header
        return this
    }

    /**
     * Sets this request's {@code Cache-Control} header, replacing any cache control headers already
     * present. If {@code cacheControl} doesn't define any directives, this clears this request's
     * cache-control headers.
     *
     * @param cacheControl of CacheControl
     *
     * @return RequestBuilder of RequestBuilder
     * @since 0.29.3
     */
    public func cacheControl(cacheControl: CacheControl): RequestBuilder {
        let value: String = cacheControl.toString()

        if (value.isEmpty()) {
            return removeHeader("Cache-Control")
        }

        return header("Cache-Control", value)
    }

    public func tag(s: String): RequestBuilder {
        this.tagsBuild.put(s, Tag(s))
        return this
    }
}
