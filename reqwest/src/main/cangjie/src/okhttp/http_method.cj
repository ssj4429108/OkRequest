/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2022-2024. All rights resvered.
 */

package ohos_app_cangjie_OkRequest.okhttp

func invalidatesCache(method: String): Bool {
    return method.equals("POST") || method.equals("PUT") || method.equals("PATCH") || method.equals("DELETE") ||
        method.equals("MOVE")
}

func permitsRequestBody(method: String): Bool {
    return method != "GET" && method != "HEAD"
}

func requiresRequestBody(method: String): Bool {
    return method.equals("POST") || method.equals("PUT") || method.equals("PATCH") || method.equals("PROPPATCH") ||
        method.equals("REPORT")
}

func redirectsToGet(method: String): Bool {
    // All requests but PROPFIND should redirect to a GET request.
    return !method.equals("PROPFIND")
}
