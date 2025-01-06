/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2022-2024. All rights resvered.
 */

package ohos_app_cangjie_reqwest.okhttp

/**
 * @file The file manage Http2Writer.
 */
class HttpHeaderUtils {
    static func hasVaryAll(response: Response): Bool {
        return hasVaryAll(response.getHeaders())
    }

    static func hasVaryAll(responseHeaders: Header): Bool {
        return varyFields(responseHeaders).contains("*")
    }

    static func varyFields(responseHeaders: Header): Set<String> {
        let result: Set<String> = HashSet()
        for ((k, v) in responseHeaders) {
            if (!equalsIgnoreCase("Vary", k)) {
                continue
            } else {
                for (varyField in v[0].split(",")) {
                    result.put(varyField.trim())
                }
            }
        }
        return result
    }

    static func varyHeaders(response: Response): Header {
        let requestHeaders = response.getNetworkResponse().getOrThrow().getRequest().getHeaders()
        let responseHeaders = response.getHeaders()
        return varyHeaders(requestHeaders, responseHeaders)
    }

    static func varyHeaders(requestHeaders: Header, responseHeaders: Header): Header {
        let varyFields: Set<String> = varyFields(responseHeaders)

        if (varyFields.isEmpty()) {
            return Header()
        }

        let header = Header()

        for ((k, v) in requestHeaders) {
            if (varyFields.contains(k)) {
                for (i in 0..v.size) {
                    header.add(k, v[i])
                }
            }
        }

        return header
    }
}
