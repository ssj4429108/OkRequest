/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2022-2024. All rights resvered.
 */

/**
 * @file
 * The file declares the Address class.
 */

package ohos_app_cangjie_OkRequest.okhttp

class RouteDatabase {
    public var mutex: Monitor = Monitor()
    private let failedRoutes: HashSet<Route> = HashSet<Route>()

    public func failed(failedRoute: Route): Unit {
        synchronized(mutex) {
            failedRoutes.put(failedRoute)
        }
    }

    public func connected(route: Route): Unit {
        synchronized(mutex) {
            failedRoutes.remove(route)
        }
    }

    public func shouldPostpone(route: Route) {
        synchronized(mutex) {
            return failedRoutes.contains(route)
        }
    }
}
