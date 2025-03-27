/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2022-2024. All rights resvered.
 */

/**
 * @file
 * The file declars the AsyncTimeout class.
 */

package ohos_app_cangjie_OkRequest.okio

import ohos.hilog.Hilog

let reentrantMutex = ReentrantMutex()
let IDLE_TIMEOUT_MILLIS: Duration = Duration.second * 60

/**
 * The class is AsyncTimeout inherited from Timeout & Equatable<AsyncTimeout>
 * @author liyanqing14
 * @since 0.32.5
 */
open class AsyncTimeout <: Timeout & Equatable<AsyncTimeout> {
    static let TIMEOUT_WRITE_SIZE: Int64 = 64 * 1024;
    private var inQueue = false

    private let lock: ReentrantMutex = ReentrantMutex()

    private static let monitor: Monitor = Monitor()

    var head: ?AsyncTimeout = None
    var next: ?AsyncTimeout = None

    private var timeoutAt: Int64 = -1

    protected var fun: ?() -> Unit = None

    /**
     * The Function is enter
     *
     * @since 0.32.5
     */
    public open func enter() {
        if (inQueue) {
            throw IllegalArgumentException("Unbalanced enter/exit")
        }
        var timeoutNanos: Int64 = timeoutNanos()
        var hasDeadline = hasDeadline();
        if (timeoutNanos == 0 && !hasDeadline) {
            return; // No timeout and no deadline? Don't bother with the queue.
        }
        inQueue = true
        scheduleTimeout(this, timeoutNanos, hasDeadline);
    }

    protected open func scheduleTimeout(node: AsyncTimeout, timeoutNanos: Int64, hasDeadline: Bool): Unit {
        synchronized(reentrantMutex) {
            match (this.head) {
                case None =>
                    this.head = AsyncTimeout()
                    this.watchdog()
                case _ => ()
            }
            let now = DateTime.now(timeZone: TimeZone.Local).nanosecond
            if (timeoutNanos != 0 && hasDeadline) {
                node.timeoutAt = min(timeoutNanos, node.deadlineNanoTime() - now)
            } else if (timeoutNanos != 0) {
                node.timeoutAt = now + timeoutNanos
            } else if (hasDeadline) {
                node.timeoutAt = node.deadlineNanoTime()
            } else {
                throw Exception("Assertion scheduleTimeout")
            }
            let remainingNanos = node.remainingNanos(now)
            var prev = this.head.getOrThrow()
            while (true) {
                match (prev.next) {
                    case Some(v) => if (remainingNanos >= v.remainingNanos(now)) {
                        continue
                    }
                    case None => ()
                }
                node.next = prev.next
                prev.next = node
                if (this.head == prev) {
                    try {
                        monitor.notify()
                    } catch (e: Exception) {
                    }
                }
                break
            }
        }
    }

    private func watchdog() {
        spawn {
            => while (true) {
                var timedout: ?AsyncTimeout = None
                synchronized(lock) {
                    timedout = awaitTimeout()
                    match (timedout) {
                        case None => continue
                        case _ => ()
                    }
                    if (timedout == this.head) {
                        this.head = None
                        return
                    }
                }
                timedout.getOrThrow().timedOut()
            }
        }
    }

    /**
     * The Function is newTimeoutException
     *
     * @param e of Exception
     *
     * @return Type of Exception
     * @since 0.32.5
     */
    public open func newTimeoutException(e: Exception): Exception {
        return InterruptedException("timeout ${e.toString()}")
    }

    /**
     * The Function is newTimeoutException
     *
     * @return Type of Exception
     * @since 0.32.5
     */
    public open func newTimeoutException(): Exception {
        return InterruptedException("timeout")
    }

    protected open func timedOut(): Unit {
        match (fun) {
            case None => ()
            case Some(v) => v()
        }
    }

    /**
     * The Function is sink
     *
     * @param sink of Sink
     *
     * @return Type of Sink
     * @since 0.32.5
     */
    public func sink(sink: Sink): Sink {
        func subWrite(source: Buffer, byteCount: Int64): Unit {
            Util.checkOffsetAndCount(source.size, 0, byteCount)
            var remaining = byteCount
            while (remaining > 0) {
                var toWrite = 0
                var s = source.head.getOrThrow()
                while (toWrite < AsyncTimeout.TIMEOUT_WRITE_SIZE) {
                    toWrite += (s.limit - s.pos)
                    if (toWrite >= remaining) {
                        toWrite = remaining
                        break
                    }
                    s = s.next.getOrThrow()
                }


                remaining -= toWrite

                var throwOnTimeout = false
                enter()
                try {
                    sink.write(source, toWrite)
                    throwOnTimeout = true
                    return
                } catch (e: Exception) {
                    throw if (!exit()) {
                        e
                    } else {
                        newTimeoutException(e)
                    }
                } finally {
                    exit(throwOnTimeout)
                }


            }
        }
        func subFlush(): Unit {
            var throwOnTimeout = false
            enter()
            try {
                sink.flush()
                throwOnTimeout = true
                return
            } catch (e: Exception) {
                throw if (!exit()) {
                    e
                } else {
                    newTimeoutException(e)
                }
            } finally {
                exit(throwOnTimeout)
            }
        }
        func subTimeout(): Timeout {
            return this
        }
        let asink = AnonymousSink()
        asink.funWrite = subWrite
        asink.funFlush = subFlush
        asink.funTimeout = subTimeout
        return asink
    }

    /**
     * The Function is source
     *
     * @param source of Source
     *
     * @return Type of Source
     * @since 0.32.5
     */
    public func source(source: Source): Source {
        func subRead(sink: Buffer, byteCount: Int64): Int64 {
            var throwOnTimeout = false
            enter()
            try {
                let result = source.read(sink, byteCount)
                throwOnTimeout = true
                return result
            } catch (e: Exception) {
                throw exit(e)
            } finally {
                exit(throwOnTimeout)
            }
        }
        func subTimeout(): Timeout {
            return this
        }
        let sourceOther = AnonymousSource()
        sourceOther.funRead = subRead
        sourceOther.funTimeout = subTimeout
        return sourceOther
    }

    func exit(e: Exception): Exception {
        if (!exit()) {
            return e
        }
        return newTimeoutException(e)
    }
    func exit(throwOnTimeout: Bool) {
        let exit = exit()
        Hilog.info(3, "ok-request", "exit: ${exit}")
        if (exit && throwOnTimeout) {
            throw newTimeoutException()
        }
    }

    /**
     * The Function is exit
     *
     * @return Type of Bool
     * @since 0.32.5
     */
    public func exit(): Bool {
        if (!inQueue) {
            return false
        }
        inQueue = false
        return cancelScheduledTimeout(this)
    }

    private func cancelScheduledTimeout(node: AsyncTimeout): Bool {
        synchronized(reentrantMutex) {
            var node = node
            var prev = this.head
            while (true) {
                match (prev) {
                    case None => break
                    case Some(v) => if (v.next.getOrThrow() == node) {
                        v.next = node.next
                        node.next = None
                        return false
                    }
                }
            }
            return true
        }
    }

    /**
     * The Function is ==
     *
     * @param that of AsyncTimeout
     *
     * @return Type of Bool
     * @since 0.32.5
     */
    public operator func ==(that: AsyncTimeout): Bool {
        return refEq(this, that)
    }
    /**
     * The Function is !=
     *
     * @param that of AsyncTimeout
     *
     * @return Type of Bool
     * @since 0.32.5
     */
    public operator func !=(that: AsyncTimeout): Bool {
        return !refEq(this, that)
    }

    /**
     * The Function is awaitTimeout
     *
     * @return Type of ?AsyncTimeout
     * @since 0.32.5
     */
    public func awaitTimeout(): ?AsyncTimeout {
        let node = head
        match (node) {
            case None =>
                let start = DateTime.now()
                monitor.wait(timeout: IDLE_TIMEOUT_MILLIS)
                if (match (head.getOrThrow().next) {
                    case None => true
                    case _ => false
                } && Duration.nanosecond >= IDLE_TIMEOUT_MILLIS) {
                    return head
                } else {
                    return None
                }
            case Some(v) =>
                var waitNanos = node.getOrThrow().remainingNanos(DateTime.now().nanosecond)
                if (waitNanos > 0) {
                    let waitMillis = waitNanos / 1000000
                    waitNanos = waitNanos - (waitMillis * 1000000)
                    monitor.wait(timeout: Duration.nanosecond * (waitNanos + waitMillis))
                    return None
                }
                head.getOrThrow().next = node.getOrThrow().next
                node.getOrThrow().next = None
                return node
        }
    }

    private func remainingNanos(now: Int64): Int64 {
        return this.timeoutAt - now
    }
}
