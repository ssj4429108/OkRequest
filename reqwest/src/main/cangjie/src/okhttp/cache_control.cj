/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2022-2024. All rights resvered.
 */

/**
 * @file
 * The file declares the CacheControl class.
 */

package ohos_app_cangjie_reqwest.okhttp

/**
 * The class is CacheControl
 * @author guo_tingtingtekla
 * @since 0.30.4
 */
public class CacheControl <: ToString {
    /**
     * Cache control request directives that require network validation of responses. Note that such
     * requests may be assisted by the cache via conditional GET requests.
     */
    public static let FORCE_NETWORK: CacheControl = CacheControlBuilder().noCache().build()

    /**
     * Cache control request directives that uses the cache only, even if the cached response is
     * stale. If the response is not available in the cache or requires server validation, the call
     * will fail with a {@code 504 Unsatisfiable Request}.
     */
    public static let FORCE_CACHE: CacheControl = CacheControlBuilder().onlyIfCached().maxStale(Int64(Int32.Max)).build(
    )

    private var noCacheInit: Bool = true

    private var noStoreInit: Bool = true

    private var maxAgeSecondsInit: Int64 = 0

    private var sMaxAgeSecondsInit: Int64 = 0

    private var isPrivateInit: Bool = true

    private var isPublicInit: Bool = true

    private var mustRevalidateInit: Bool = true

    private var maxStaleSecondsInit: Int64 = 0

    private var minFreshSecondsInit: Int64 = 0

    private var onlyIfCachedInit: Bool = true

    private var noTransformInit: Bool = true

    private var immutableInit: Bool = true

    // Lazily computed, null if absent
    var headerValue: String = ""

    private init(
        noCache: Bool,
        noStore: Bool,
        maxAgeSeconds: Int64,
        sMaxAgeSeconds: Int64,
        isPrivate: Bool,
        isPublic: Bool,
        mustRevalidate: Bool,
        maxStaleSeconds: Int64,
        minFreshSeconds: Int64,
        onlyIfCached: Bool,
        noTransform: Bool,
        immutable: Bool,
        headerValue: String
    ) {
        this.noCacheInit = noCache
        this.noStoreInit = noStore
        this.maxAgeSecondsInit = maxAgeSeconds
        this.sMaxAgeSecondsInit = sMaxAgeSeconds
        this.isPrivateInit = isPrivate
        this.isPublicInit = isPublic
        this.mustRevalidateInit = mustRevalidate
        this.maxStaleSecondsInit = maxStaleSeconds
        this.minFreshSecondsInit = minFreshSeconds
        this.onlyIfCachedInit = onlyIfCached
        this.noTransformInit = noTransform
        this.immutableInit = immutable
        this.headerValue = headerValue
    }

    init(builder: CacheControlBuilder) {
        this.noCacheInit = builder.noCacheBuild
        this.noStoreInit = builder.noStoreBuild
        this.maxAgeSecondsInit = builder.maxAgeSeconds
        this.sMaxAgeSecondsInit = -1
        this.isPrivateInit = false
        this.isPublicInit = false
        this.mustRevalidateInit = false
        this.maxStaleSecondsInit = builder.maxStaleSeconds
        this.minFreshSecondsInit = builder.minFreshSeconds
        this.onlyIfCachedInit = builder.onlyIfCachedBuild
        this.noTransformInit = builder.noTransformBuild
        this.immutableInit = builder.immutableBuild
    }

    public static func builder(): CacheControlBuilder {
        return CacheControlBuilder()
    }

    /**
     * In a response, this field is name "no-cache" is misleading. It does not prevent us from caching
     * the response it only means we have to validate the response with the origin server before
     * returning it. We can do this with a conditional GET.
     *
     * <p>In a request, it means do not use a cache to satisfy the request.
     *
     * @return Bool
     */
    public func noCache(): Bool {
        return noCacheInit
    }

    /**
     * If true, this response should not be cached.
     *
     * @return Bool
     */
    public func noStore(): Bool {
        return noStoreInit
    }

    /**
     * The duration past the response is served date that it can be served without validation.
     *
     * @return Int64
     */
    public func maxAgeSeconds(): Int64 {
        return maxAgeSecondsInit
    }

    /**
     * The "s-maxage" directive is the max age for shared caches. Not to be confused with "max-age"
     * for non-shared caches, As in Firefox and Chrome, this directive is not honored by this cache.
     *
     * @return Int64
     */
    public func sMaxAgeSeconds(): Int64 {
        return sMaxAgeSecondsInit
    }

    /**
     * The Function is isPrivate
     *
     * @return Type of Bool
     * @since 0.30.4
     */
    public func isPrivate(): Bool {
        return isPrivateInit
    }

    /**
     * The Function is isPublic
     *
     * @return Type of Bool
     * @since 0.30.4
     */
    public func isPublic(): Bool {
        return isPublicInit
    }

    /**
     * The Function is mustRevalidate
     *
     * @return Type of Bool
     * @since 0.30.4
     */
    public func mustRevalidate(): Bool {
        return mustRevalidateInit
    }

    /**
     * The Function is maxStaleSeconds
     *
     * @return Type of Int64
     * @since 0.30.4
     */
    public func maxStaleSeconds(): Int64 {
        return maxStaleSecondsInit
    }

    /**
     * The Function is minFreshSeconds
     *
     * @return Type of Int64
     * @since 0.30.4
     */
    public func minFreshSeconds(): Int64 {
        return minFreshSecondsInit
    }

    /**
     * The Function is onlyIfCached
     *
     * @return Type of Bool
     * @since 0.30.4
     */
    public func onlyIfCached(): Bool {
        return onlyIfCachedInit
    }

    /**
     * The Function is noTransform
     *
     * @return Type of Bool
     * @since 0.30.4
     */
    public func noTransform(): Bool {
        return noTransformInit
    }

    /**
     * The Function is immutable
     *
     * @return Type of Bool
     * @since 0.30.4
     */
    public func immutable(): Bool {
        return immutableInit
    }

    public static func parse(header: Header): CacheControl {
        var noCache: Bool = false
        var noStore: Bool = false
        var maxAgeSeconds: Int64 = -1
        var sMaxAgeSeconds: Int64 = -1
        var isPrivate: Bool = false
        var isPublic: Bool = false
        var mustRevalidate: Bool = false
        var maxStaleSeconds: Int64 = -1
        var minFreshSeconds: Int64 = -1
        var onlyIfCached: Bool = false
        var noTransform: Bool = false
        var immutable: Bool = false
        var canUseHeaderValue: Bool = true
        var headerValue: String = ""

        for ((name, v) in header) {
            for (value in v) {
                if (equalsIgnoreCase(name, "cache-control")) {
                    if (v.size > 1) {
                        // Multiple cache-control headers means we can't use the raw value.
                        canUseHeaderValue = false
                    } else {
                        headerValue = value
                    }
                } else if (equalsIgnoreCase("name", "pragma")) {
                    // Might specify additional cache-control params. We invalidate just in case.
                    canUseHeaderValue = false
                } else {
                    continue
                }

                var pos: Int64 = 0

                while (pos < value.size) {
                    let tokenStart: Int64 = pos
                    pos = Util.skipUntil(value, pos, "=,;")
                    let directive: String = value.substring(tokenStart, pos - tokenStart).trim()
                    var parameter: String = ""
                    if (pos == value.size || value[pos] == b',' || value[pos] == b';') {
                        pos++ // consume ',' or ';' (if necessary)
                        parameter = ""
                    } else {
                        pos++ // consume '='
                        pos = Util.skipWhitespace(value, pos)

                        if (pos < value.size && value[pos] == b'\"') {
                            pos++ // consume '"' open quote
                            let parameterStart: Int64 = pos
                            pos = Util.skipUntil(value, pos, "\"")
                            parameter = value.substring(parameterStart, pos - parameterStart)
                            pos++ // consume '"' close quote (if necessary)
                        } else {
                            let parameterStart: Int64 = pos
                            pos = Util.skipUntil(value, pos, ",;")
                            parameter = value.substring(parameterStart, pos - parameterStart).trim()
                        }
                    }

                    if (equalsIgnoreCase("no-cache", directive)) {
                        noCache = true
                    } else if (equalsIgnoreCase("no-store", directive)) {
                        noStore = true
                    } else if (equalsIgnoreCase("max-age", directive)) {
                        maxAgeSeconds = Util.parseSeconds(parameter, -1)
                    } else if (equalsIgnoreCase("s-maxage", directive)) {
                        sMaxAgeSeconds = Util.parseSeconds(parameter, -1)
                    } else if (equalsIgnoreCase("private", directive)) {
                        isPrivate = true
                    } else if (equalsIgnoreCase("public", directive)) {
                        isPublic = true
                    } else if (equalsIgnoreCase("must-revalidate", directive)) {
                        mustRevalidate = true
                    } else if (equalsIgnoreCase("max-stale", directive)) {
                        maxStaleSeconds = Util.parseSeconds(parameter, Int64(Int32.Max))
                    } else if (equalsIgnoreCase("min-fresh", directive)) {
                        minFreshSeconds = Util.parseSeconds(parameter, -1)
                    } else if (equalsIgnoreCase("only-if-cached", directive)) {
                        onlyIfCached = true
                    } else if (equalsIgnoreCase("no-transform", directive)) {
                        noTransform = true
                    } else if (equalsIgnoreCase("immutable", directive)) {
                        immutable = true
                    }
                }
            }
        }

        if (!canUseHeaderValue) {
            headerValue = ""
        }

        return CacheControl(
            noCache,
            noStore,
            maxAgeSeconds,
            sMaxAgeSeconds,
            isPrivate,
            isPublic,
            mustRevalidate,
            maxStaleSeconds,
            minFreshSeconds,
            onlyIfCached,
            noTransform,
            immutable,
            headerValue
        )
    }

    /**
     * The Function is toString
     *
     * @return Type of String
     * @since 0.30.4
     */
    public func toString(): String {
        let result: String = headerValue
        if (result != "") {
            return result
        } else {
            headerValue = getHeaderValue()
            return headerValue
        }
    }

    private func getHeaderValue(): String {
        var result: StringBuilder = StringBuilder()
        if (noCacheInit) {
            result.append("no-cache, ")
        }
        if (noStoreInit) {
            result.append("no-store, ")
        }
        if (maxAgeSecondsInit != -1) {
            result.append("max-age=${maxAgeSecondsInit}, ")
        }
        if (sMaxAgeSecondsInit != -1) {
            result.append("s-maxage=${sMaxAgeSecondsInit}, ")
        }
        if (isPrivateInit) {
            result.append("private, ")
        }
        if (isPublicInit) {
            result.append("public, ")
        }
        if (mustRevalidateInit) {
            result.append("must-revalidate, ")
        }
        if (maxStaleSecondsInit != -1) {
            result.append("max-stale=${maxStaleSecondsInit}, ")
        }
        if (minFreshSecondsInit != -1) {
            result.append("min-fresh=${minFreshSecondsInit}, ")
        }
        if (onlyIfCachedInit) {
            result.append("only-if-cached, ")
        }
        if (noTransformInit) {
            result.append("no-transform, ")
        }
        if (immutableInit) {
            result.append("immutable, ")
        }
        if (result.size == 0) {
            return ""
        }
        return result.toString()[..result.size - 2].trim()
    }
}
