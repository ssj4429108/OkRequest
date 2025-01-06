/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2022-2024. All rights resvered.
 */

/**
 * @file The file declares the ConcurrentQueue class.
 */

package ohos_app_cangjie_reqwest.okhttp

/**
 * The class is ConcurrentQueue<T>
 * @since
 */
class ConcurrentQueue<T> <: Iterable<T> {
    private let maxQueueMemory: Int64

    private var list: ArrayList<T> = ArrayList<T>(32)

    private let m: Monitor

    /**
     * The Function is init constructor
     *
     *
     * @since 29.3
     */
    public init(mutex: Monitor) {
        this.m = mutex
        this.maxQueueMemory = 1024
    }

    public func iterator(): Iterator<T> {
        return list.iterator()
    }

    /**
     * The Function is add
     *
     * @param The param is item of T
     *
     * @since
     */
    public func add(item: T) {
        m.lock()
        try {
            this.list.append(item)
        } finally {
            m.unlock()
        }
    }

    public func get(index: Int64): T {
        synchronized(m) {
            return list[index]
        }
    }

    public func remove(index: Int64) {
        synchronized(m) {
            list.remove(index)
        }
    }

    public func removeIf(predicate: (T) -> Bool) {
        synchronized(m) {
            list.removeIf(predicate)
        }
    }

    public func size(): Int64 {
        synchronized(m) {
            list.size
        }
    }

    public func toArrayList(): ArrayList<T> {
        synchronized(m) {
            return ArrayList<T>(list)
        }
    }
}
