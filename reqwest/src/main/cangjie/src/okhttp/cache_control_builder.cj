/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2022-2024. All rights resvered.
 */

/**
 * @file
 * The file declares the CacheControlBuilder class.
 */

package ohos_app_cangjie_reqwest.okhttp

/**
 * Builds a CacheControl request header.
 * @author guo_tingtingtekla
 * @since 0.30.4
 */
public class CacheControlBuilder <: Builder<CacheControl> {
    public var noCacheBuild: Bool = false

    public var noStoreBuild: Bool = false

    public var maxAgeSeconds: Int64 = -1

    public var maxStaleSeconds: Int64 = -1

    public var minFreshSeconds: Int64 = -1

    public var onlyIfCachedBuild: Bool = false

    public var noTransformBuild: Bool = false

    public var immutableBuild: Bool = false

    /**
     * Do not use cache, all go online
     *
     * @return CacheControlBuilder
     */
    public func noCache(): CacheControlBuilder {
        this.noCacheBuild = true
        return this
    }

    /**
     * Do not use cache and do not store cache
     *
     * @return CacheControlBuilder
     */
    public func noStore(): CacheControlBuilder {
        this.noStoreBuild = true
        return this
    }

    /**
     * Sets the maximum age of a cached response. If the cache response is age exceeds
     * maxAge, it will not be used and a network request will be made.
     *
     * @param maxAge of Int64
     *
     * @return CacheControlBuilder
     */
    public func maxAge(maxAge: Int64): CacheControlBuilder {
        if (maxAge < 0) {
            throw IllegalArgumentException("maxAge : ${maxAge} < 0")
        }
        this.maxAgeSeconds = maxAge
        return this
    }

    /**
     * Accept cached responses that have exceeded their freshness lifetime by up to
     * maxStale. If unspecified, stale cache responses will not be used.
     *
     * @param maxStale of Int64
     *
     * @return CacheControlBuilder
     */
    public func maxStale(maxStale: Int64): CacheControlBuilder {
        if (maxStale < 0) {
            throw IllegalArgumentException("maxStale : ${maxStale} < 0")
        }
        this.maxStaleSeconds = maxStale
        return this
    }

    /**
     * Sets the minimum number of seconds that a response will continue to be fresh for. If the
     * response will be stale when  minFresh have elapsed, the cached response will not be
     * used and a network request will be made.
     *
     * @param minFresh of Int64
     *
     * @return CacheControlBuilder
     */
    public func minFresh(minFresh: Int64): CacheControlBuilder {
        if (minFresh < 0) {
            throw IllegalArgumentException("minFresh : ${minFresh} < 0")
        }
        this.minFreshSeconds = minFresh
        return this
    }

    /**
     * Only accept the response if it is in the cache. If the response is not cached, a {@code 504
     * Unsatisfiable Request} response will be returned.
     *
     * @return CacheControlBuilder
     */
    public func onlyIfCached(): CacheControlBuilder {
        this.onlyIfCachedBuild = true
        return this
    }

    /**
     * Do not accept a transformed response, no transcoding
     *
     * @return CacheControlBuilder
     */
    public func noTransform(): CacheControlBuilder {
        this.noTransformBuild = true
        return this
    }

    /**
     * The Function is immutable
     *
     * @return Type of CacheControlBuilder
     * @since 0.30.4
     */
    public func immutable(): CacheControlBuilder {
        this.immutableBuild = true
        return this
    }

    public func build(): CacheControl {
        return CacheControl(this)
    }
}
