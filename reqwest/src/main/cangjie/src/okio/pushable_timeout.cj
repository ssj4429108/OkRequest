/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2022-2024. All rights resvered.
 */

/**
 * @file
 * The file declars the PushableTimeout class.
 */

package ohos_app_cangjie_OkRequest.okio

class PushableTimeout <: Timeout {

    private var ptime: Timeout = Timeout()
    private var phasDeadline: Bool = true
    private var pdeadlineNanoTime: Int64 = 0
    private var ptimeoutNanos: Int64 = 0

    public init(){

    }
    
    func push(ptime: Timeout) {
        this.ptime = ptime
        this.phasDeadline = ptime.hasDeadline()
        try{
        this.pdeadlineNanoTime = ptime.deadlineNanoTime()
        }catch(e: Exception){

        }
        this.ptimeoutNanos = ptime.timeoutNanos()
        if (pdeadlineNanoTime != ptimeoutNanos) {
            pdeadlineNanoTime = -1
        }
        ptime.timeout(minTimeout(ptimeoutNanos , timeoutNanos()))

        if (phasDeadline && hasDeadline()) {
            ptime.deadlineNanoTime(min(deadlineNanoTime(), pdeadlineNanoTime))
        } else if (hasDeadline()) {
            ptime.deadlineNanoTime(deadlineNanoTime())
        }
    }

    func pop() {
        ptime.timeout(ptimeoutNanos)
        if (phasDeadline) {
            ptime.deadlineNanoTime(pdeadlineNanoTime)
        } else {
            ptime.clearDeadline()
        }
    }
}
