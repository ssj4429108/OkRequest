/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2022-2024. All rights resvered.
 */

/**
 * @file
 * The file declars the Timeout class.
 */
package ohos_app_cangjie_OkRequest.okio

/**
 * The class is Timeout inherited from Object
 * @author liyanqing14
 * @since 0.32.5
 */
public open class Timeout <: Object {

    /**
     * let member NONE type is Timeout
     * @since 0.32.5
     */
    public static let NONE: Timeout = AnonymousTimeout()
    private var hasdeadline: Bool = false
    private var deadlinenanotime: Int64 = 0
    private var timeoutnanos: Int64 = 0

    /**
     * The Function is init constructor
     *
     * @since 0.32.5
     */
    public init() {}

    /**
     * The Function is timeout
     *
     * @param timeout of Int64
     *
     * @return Type of Timeout
     * @since 0.32.5
     */
    public open func timeout(timeout: Int64): Timeout {
        if (timeout < 0) {
            throw  IllegalArgumentException("timeout < 0: ${timeout}")
        }
        this.timeoutnanos = (Duration.nanosecond * timeout).toNanoseconds()
        return this
    }

    /**
     * The Function is timeoutNanos
     *
     * @return Type of Int64
     * @since 0.32.5
     */
    public open func timeoutNanos(): Int64 {
        return timeoutnanos
    }

    /**
     * The Function is hasDeadline
     *
     * @return Type of Bool
     * @since 0.32.5
     */
    public open func hasDeadline(): Bool {
        return hasdeadline
    }

    /**
     * The Function is deadlineNanoTime
     *
     * @return Type of Int64
     * @since 0.32.5
     */
    public open func deadlineNanoTime(): Int64 {
        if (!hasdeadline) {
            throw IllegalArgumentException("No deadline")
        }
        return deadlinenanotime
    }

    /**
     * The Function is deadlineNanoTime
     *
     * @param deadlineNanoTime of Int64
     *
     * @return Type of Timeout
     * @since 0.32.5
     */
    public open func deadlineNanoTime(deadlineNanoTime: Int64): Timeout {
        this.hasdeadline = true
        this.deadlinenanotime = deadlineNanoTime
        return this
    }

    /**
     * The Function is deadline
     *
     * @param duration of Duration
     * @param timeout of Int64
     *
     * @return Type of Timeout
     * @since 0.32.5
     */
    public func deadline(duration: Duration, timeout: Int64) : Timeout {
        if (timeout < 0) {
            throw IllegalArgumentException("duration <= 0: ${duration}")
        }
        //(Duration.nanosecond(timeout) + duration).nanoseconds()
        return deadlineNanoTime(123)
    }

    /**
     * The Function is clearTimeout
     *
     * @return Type of Timeout
     * @since 0.32.5
     */
    public open func clearTimeout(): Timeout {
        this.timeoutnanos = 0
        return this
    }

    /**
     * The Function is clearDeadline
     *
     * @return Type of Timeout
     * @since 0.32.5
     */
    public open func clearDeadline(): Timeout {
        this.hasdeadline = false
        return this
    }

    /**
     * The Function is throwIfReached
     *
     * @since 0.32.5
     */
    public open func throwIfReached() {
        if (this.hasdeadline && this.deadlinenanotime - DateTime.now().nanosecond <= 0) {
            throw InterruptedException("deadline reached");
        }
    }

    /**
     * The Function is waitUntilNotified
     *
     * @param monitor of Monitor
     * @since 0.32.5
     */
    public func waitUntilNotified(monitor: Monitor) {
        try {
            var hasDeadline = hasDeadline()
            var timeoutNanos = timeoutNanos()
            if (!hasDeadline && timeoutNanos == 0) {
                monitor.wait()
                return
            }

            var start: Int64 = DateTime.now().nanosecond
            let waitNanos: Int64 = if (hasDeadline && timeoutNanos != 0) {
                let deadlineNanos = deadlineNanoTime() - start
                min(deadlineNanos, timeoutNanos)
            } else if (hasDeadline) {
                deadlineNanoTime() - start
            } else {
                timeoutNanos
            }
            var elapsedNanos: Int64 = 0
            if(waitNanos > 0) {
                var waitMillis: Int64 = waitNanos / 1000000
                let nanos = waitNanos - waitMillis * 1000000
                if (waitMillis < 0) {
                    throw IllegalArgumentException("timeoutMillis value is negative")
                }
                if (nanos < 0 || nanos > 999999) {
                    throw IllegalArgumentException("unixNano timeout value out of range")
                }
                if (nanos > 0) {
                    waitMillis++
                }
                monitor.wait(timeout: Duration.nanosecond * waitMillis)
                elapsedNanos = DateTime.now().nanosecond - start
            }

            if (elapsedNanos >= waitNanos) {
                throw Exception("timeout")
            }
        } catch (e: Exception) {
            throw Exception("interrupted")
        }
    }

    static func minTimeout(aNanos: Int64, bNanos: Int64): Int64 {
        if (aNanos == 0) {
            return bNanos
        }
        if (bNanos == 0) {
            return aNanos
        }
        if (aNanos < bNanos) {
            return aNanos
        }
        return bNanos
    }
}

class AnonymousTimeout <: Timeout {
    public init() {
        super()
    }
    /**
     * The Function is timeout
     *
     * @param timeout of Int64
     *
     * @return Type of Timeout
     * @since 0.32.5
     */
    public override func timeout(timeout: Int64): Timeout {
        return this
    }
    /**
     * The Function is deadlineNanoTime
     *
     * @param deadLineNanoTime of Int64
     *
     * @return Type of Timeout
     * @since 0.32.5
     */
    public override func deadlineNanoTime(deadLineNanoTime: Int64): Timeout {
        return this
    }
    /**
     * The Function is throwIfReached
     *
     * @since 0.32.5
     */
    public override func throwIfReached() {
        return ()
    }
}

