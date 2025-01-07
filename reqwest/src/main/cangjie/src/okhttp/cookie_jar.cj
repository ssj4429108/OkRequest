/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2022-2024. All rights resvered.
 */

/**
 * @file
 * The file declares the CookieJar impls.
 */

package ohos_app_cangjie_OkRequest.okhttp

/**
 * The class NoCookieJar
 *
 * Use no Cookie, this is the default jar in httpClient
 *
 * @author luoyukai4
 * @since 0.34.3
 */
class NoCookieJar <: CookieJar {
    /**
     * The Function is saveFromResponse
     *
     * @param url of URL
     * @param cookies of Array<Cookie>
     *
     * @return Type of Unit
     * @since 0.34.3
     */
    public func saveFromResponse(_: URL, _: Array<Cookie>): Unit {}

    /**
     * The Function is loadForRequest
     *
     * @param url of URL
     *
     * @return Type of Array<Cookie>
     * @since 0.34.3
     */
    public func loadForRequest(_: URL): Array<Cookie> {
        return Array<Cookie>()
    }
}

/**
 * The class SimpleCookieJar
 *
 * provide a SimpleCookieJar for users to use Cookie
 * save the Cookies on memory and then also read them from memory
 * it has no Persistence
 *
 * @author luoyukai4
 * @since 0.34.3
 */
class SimpleCookieJar <: CookieJar {
    /* let member delegate type is HttpCookieJar */
    private let delegate: HttpCookieJar = HttpCookieJar.createDefaultCookieJar(ArrayList(), true)

    public func saveFromResponse(url: URL, cookies: Array<Cookie>): Unit {
        delegate.storeCookies(url, ArrayList(cookies))
    }

    /**
     * The Function is loadForRequest
     *
     * @param url of URL
     *
     * @return Type of Array<Cookie>
     * @since 0.34.3
     */
    public func loadForRequest(url: URL): Array<Cookie> {
        return delegate.getCookies(url).toArray()
    }
}

/**
 * The Function is getSimpleCookieJar
 *
 * @return Type of CookieJar
 * @since 0.34.3
 */
public func getSimpleCookieJar(): CookieJar {
    return SimpleCookieJar()
}
