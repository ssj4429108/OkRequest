/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2022-2024. All rights resvered.
 */

/**
 * @file
 * The file declares the Address class.
 */

package ohos_app_cangjie_OkRequest.okhttp

/**
 * The class is Route
 * @author guo_tingtingtekla,luoyukai4
 * @since 0.29.3
 */
public class Route <: Hashable & Equatable<Route> {
    /** var member address type is Address */
    let address: Address
    let inetSocketAddress: SocketAddress

    /**
     * The Function is init constructor
     *
     * @param address of Address
     * @param inetSocketAddress of SocketAddress
     * @since 0.29.3
     */
    public init(address: Address, inetSocketAddress: SocketAddress) {
        this.address = address
        this.inetSocketAddress = inetSocketAddress
    }

    /**
     * The Function is init constructor
     *
     * @param address of Address
     * @since 0.29.3
     */

    /**
     * The Function is getAddress
     * @return Type of Address
     * @since 0.29.3
     */
    public func getAddress(): Address {
        return address
    }

    /**
     * The Function is getAddress
     * @return Type of Address
     * @since 0.29.3
     */
    public func getInetSocketAddress(): SocketAddress {
        return inetSocketAddress
    }

    @OverflowWrapping
    public func hashCode(): Int64 {
        var result: Int64 = 17
        result = 31 * result + address.hashCode()

        //result = 31 * result + inetSocketAddress.hashCode()
        return result
    }

    public operator func ==(rhs: Route): Bool {
        return address == rhs.getAddress()
    }

    public operator func !=(rhs: Route): Bool {
        if (this == rhs) {
            return false
        } else {
            return true
        }
    }
}
