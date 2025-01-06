/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2022-2024. All rights resvered.
 */

/**
 * @file
 * The file declares the Dispatcher class.
 */

package ohos_app_cangjie_reqwest.okhttp

/**
 * The class is Dispatcher
 * @author guo_tingtingtekla,luoyukai4
 * @since 0.29.3
 */
public class Dispatcher {
    /** var member mutex type is Monitor */
    let mutex: Monitor = Monitor()

    /* var member maxRequests type is Int64 */
    private var maxRequests: Int64 = 64

    /* var member maxRequestsPerHost type is Int64 */
    private var maxRequestsPerHost: Int64 = 5

    /* var member readyAsyncCalls type is ConcurrentQueue<AsyncCall> */
    private var readyAsyncCalls: ConcurrentQueue<AsyncCall> = ConcurrentQueue<AsyncCall>(mutex)

    /* var member runningAsyncCalls type is ConcurrentQueue<AsyncCall> */
    private var runningAsyncCalls: ConcurrentQueue<AsyncCall> = ConcurrentQueue<AsyncCall>(mutex)

    /* var member runningSyncCalls type is ConcurrentQueue<RealCall> */
    private var runningSyncCalls: ConcurrentQueue<RealCall> = ConcurrentQueue<RealCall>(mutex)

    private var idleCallback: Option<() -> Unit> = Option.None

    /**
     * The Function is setIdleCallback
     *
     * @param idleCallback of Option<()->Unit>
     * @since 0.30.4
     */
    public func setIdleCallback(idleCallback: Option<() -> Unit>) {
        this.idleCallback = idleCallback
    }

    /**
     * The Function is setMaxRequests
     *
     * @param maxRequests of Int64
     *
     * @return Type of Unit
     * @since 0.29.3
     */
    public func setMaxRequests(maxRequests: Int64): Unit {
        if (maxRequests < 1) {
            throw IllegalArgumentException("max < 1:${ maxRequests}")
        }

        synchronized(mutex) {
            this.maxRequests = maxRequests
        }
        promoteAndExecute()
    }

    /**
     * The Function is getMaxRequests
     *
     * @return Type of Int64
     * @since 0.30.4
     */
    public func getMaxRequests(): Int64 {
        synchronized(mutex) {
            return maxRequests
        }
    }

    /**
     * The Function is setMaxRequestsPerHost
     *
     * @param maxRequestsPerHost of Int64
     *
     * @return Type of Unit
     * @since 0.30.4
     */
    public func setMaxRequestsPerHost(maxRequestsPerHost: Int64): Unit {
        if (maxRequestsPerHost < 1) {
            throw IllegalArgumentException("max < 1: ${ maxRequestsPerHost}")
        }

        synchronized(mutex) {
            this.maxRequestsPerHost = maxRequestsPerHost
        }
        promoteAndExecute()
    }

    /**
     * The Function is getMaxRequestsPerHost
     *
     * @return Type of Int64
     * @since 0.30.4
     */
    public func getMaxRequestsPerHost(): Int64 {
        synchronized(mutex) {
            return maxRequestsPerHost
        }
    }

    /**
     * The Function is executed
     *
     * @param call of RealCall
     *
     * @return Type of Unit
     * @since 0.29.3
     */
    func executed(call: RealCall): Unit {
        synchronized(mutex) {
            runningSyncCalls.add(call)
        }
    }

    /*
     * The Function is finished
     *
     * @param calls of ConcurrentQueue<RealCall>
     * @param call of RealCall
     *
     * @return Type of Unit
     * @since 0.29.3
     */
    private func finished(calls: ConcurrentQueue<RealCall>, call: RealCall): Unit {
        var idleCallback: Option<() -> Unit>
        synchronized(mutex) {
            for (index in 0..calls.size()) {
                if (refEq(call, calls.get(index))) {
                    calls.remove(index)
                    break
                }
            }
            idleCallback = this.idleCallback
        }
        var isRunning: Bool = promoteAndExecute()

        if (!isRunning) {
            match (idleCallback) {
                case Some(cb) =>
                    spawn {
                        cb()
                    }
                    ()
                case None => ()
            }
        }
    }

    private func finished(calls: ConcurrentQueue<AsyncCall>, call: AsyncCall): Unit {
        var idleCallback: Option<() -> Unit>
        synchronized(mutex) {
            for (index in 0..calls.size()) {
                if (refEq(call, calls.get(index))) {
                    calls.remove(index)
                    break
                }
            }
            idleCallback = this.idleCallback
        }
        var isRunning: Bool = promoteAndExecute()

        if (!isRunning) {
            match (idleCallback) {
                case Some(cb) =>
                    spawn {
                        cb()
                    }
                    ()
                case None => ()
            }
        }
    }

    /*
     * The Function is finished
     *
     * @param call of RealCall
     *
     * @return Type of Unit
     * @since 0.29.3
     */
    func finished(call: RealCall): Unit {
        finished(runningSyncCalls, call)
    }

    func finished(call: AsyncCall) {
        synchronized(mutex) {
            call.getCallsPerHost().fetchSub(1)
            finished(runningAsyncCalls, call)
        }
    }

    /**
     * The Function is enqueue
     *
     * @param call of AsyncCall
     *
     * @return Type of Unit
     * @since 0.29.3
     */
    func enqueue(call: AsyncCall): Unit {
        synchronized(mutex) {
            readyAsyncCalls.add(call)
            if (!call.get().forWebSocket) {
                match (findExistingCallWithHost(call.host())) {
                    case Some(existingCall) => call.reuseCallsPerHostFrom(existingCall)
                    case None => ()
                }
            }
        }
        promoteAndExecute()
    }

    /*
     * The Function is findExistingCallWithHost
     *
     * @param host of String
     *
     * @return Type of Option<AsyncCall>
     * @since 0.29.3
     */
    private func findExistingCallWithHost(host: String): Option<AsyncCall> {
        for (i in (0..runningAsyncCalls.size())) {
            if (runningAsyncCalls.get(i).host().equals(host)) {
                return runningAsyncCalls.get(i)
            }
        }

        for (i in (0..readyAsyncCalls.size())) {
            if (readyAsyncCalls.get(i).host().equals(host)) {
                return readyAsyncCalls.get(i)
            }
        }

        return None
    }

    /**
     * The Function is cancelAll
     *
     * @since 0.30.4
     */
    public func cancelAll() {
        synchronized(mutex) {
            for (index in (0..readyAsyncCalls.size())) {
                let asyncCall: AsyncCall = readyAsyncCalls.get(index)
                asyncCall.cancel()
            }
            for (index in (0..runningAsyncCalls.size())) {
                let asyncCall: AsyncCall = runningAsyncCalls.get(index)
                asyncCall.cancel()
            }
            for (index in (0..runningSyncCalls.size())) {
                let call: RealCall = runningSyncCalls.get(index)
                call.cancel()
            }
        }
    }

    /*
     * The Function is promoteAndExecute
     *
     * @return Type of Bool
     * @since 0.29.3
     */
    func promoteAndExecute(): Bool {
        let executableCalls: ArrayList<AsyncCall> = ArrayList<AsyncCall>()
        var isRunning: Bool
        synchronized(mutex) {
            let arr = ArrayList<Int64>()
            for (index in 0..readyAsyncCalls.size()) {
                let asyncCall: AsyncCall = readyAsyncCalls.get(index)
                if (runningAsyncCalls.toArrayList().size >= maxRequests) {
                    break
                    // Max capacity.
                }

                if (asyncCall.callsPerHost.load() >= maxRequestsPerHost) {
                    continue
                    // Host max capacity.
                }
                arr.append(index)
                asyncCall.callsPerHost.fetchAdd(1)
                executableCalls.append(asyncCall)
                runningAsyncCalls.add(asyncCall)
            }

            for (i in 0..arr.size) {
                readyAsyncCalls.remove(arr[i])
            }

            isRunning = runningAsyncCalls.toArrayList().size + runningSyncCalls.toArrayList().size > 0
        }

        for (i in 0..executableCalls.size) {
            executableCalls[i].executeOn()
        }

        return isRunning
    }

    /**
     * The Function is queuedCallsCount
     *
     * @since 0.30.4
     */
    public func queuedCallsCount(): Int64 {
        synchronized(mutex) {
            return readyAsyncCalls.size()
        }
    }

    /**
     * The Function is queuedCalls
     *
     * @return Type of ArrayList<Call>
     * @since 0.34.3
     */
    public func queuedCalls(): ArrayList<Call> {
        let list = readyAsyncCalls.toArrayList()
        let result = ArrayList<Call>()

        synchronized(mutex) {
            for (i in 0..list.size) {
                result.append(list[i].get())
            }
        }

        return result
    }

    /**
     * The Function is runningCalls
     *
     * @return Type of ArrayList<Call>
     * @since 0.34.3
     */
    public func runningCalls(): ArrayList<Call> {
        let syncList: ArrayList<RealCall> = runningSyncCalls.toArrayList()
        let asyncList: ArrayList<AsyncCall> = runningAsyncCalls.toArrayList()
        let result = ArrayList<Call>()

        synchronized(mutex) {
            for (i in 0..asyncList.size) {
                syncList.append(asyncList[i].get())
            }
        }

        for (i in 0..syncList.size) {
            result.append(syncList[i])
        }

        return result
    }

    /**
     * The Function is runningCallsCount
     *
     * @return Type of Int64
     * @since 0.30.4
     */
    public func runningCallsCount(): Int64 {
        synchronized(mutex) {
            return runningAsyncCalls.size() + runningSyncCalls.size()
        }
    }
}
