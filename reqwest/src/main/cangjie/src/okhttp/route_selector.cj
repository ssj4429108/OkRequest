/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2022-2024. All rights resvered.
 */

/**
 * @file
 * The file declares the RouteSelector class.
 */

package ohos_app_cangjie_reqwest.okhttp

let routeCache: HashMap<Address, ArrayList<Route>> = HashMap<Address, ArrayList<Route>>()

/**
 * The class is RouteSelector
 * @author guo_tingtingtekla,luoyukai4
 * @since 0.29.3
 */
class RouteSelector {
    /** var member address type is Address */
    private let address: Address

    private let routeDatabase: RouteDatabase

    private var index: UInt64 = 0

    private let allRoutes: ArrayList<Route> = ArrayList<Route>()

    private var hasAll: Bool = false

    private let call: Call

    private let eventListener: EventListener

    /**
     * The Function is init constructor
     *
     * @param address of Address
     * @param call of Call
     * @since 0.29.3
     */
    public init(address: Address, routeDatabase: RouteDatabase, call: Call, eventListener: EventListener) {
        this.address = address
        this.routeDatabase = routeDatabase
        this.call = call
        this.eventListener = eventListener
    }

    /**
     * The Function is next
     *
     * @return Type of Route
     * @since 0.29.3
     */
    public func next(): Option<Route> {
        if (!hasNext()) {
            throw IndexOutOfBoundsException()
        }
        let route = allRoutes[Int64(index)]
        index++
        return hasPost(route)
    }

    private func hasPost(route: Route): Option<Route> {
        if (!routeDatabase.shouldPostpone(route)) {
            return route
        } else {
            return next()
        }
    }

    public func hasNext(): Bool {
        if (!hasAll) {
            getAll()
        }
        return index < UInt64(allRoutes.size)
    }

    public func getAll(): ArrayList<Route> {
        hasAll = true
        if (routeCache.contains(address)) {
            allRoutes.appendAll(routeCache[address])
            return allRoutes
        }

        if (!allRoutes.isEmpty()) {
            return allRoutes
        }

        let url = address.getUrl()
        var socketHost = url.hostName
        let port: UInt16 = match (UInt16.tryParse(url.port)) {
            case Some(v) => v
            case None => if (url.toString().startsWith("https")) {
                portTrans(443)
            } else {
                portTrans(80)
            }
        }
        eventListener.dnsStart(call, socketHost)

        let arr = resolveDomain(TCP, socketHost)

        for (i in 0..arr.size) {
            let route: (SocketAddressKind, Array<UInt8>) = arr[i]
            allRoutes.append(Route(address, SocketAddress(route[0], route[1], port)))
        }

        eventListener.dnsEnd(call, socketHost, allRoutes)
        routeCache.put(address, allRoutes)
        return allRoutes
    }
}
