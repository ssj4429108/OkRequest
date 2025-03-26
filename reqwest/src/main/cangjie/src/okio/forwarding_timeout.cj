/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2022-2024. All rights resvered.
 */

/**
 * @file
 * The file declars the ForwardingSink abstract class.
 */

package ohos_app_cangjie_OkRequest.okio

/**
 * The interface is ForwardingTimeout inherited from Timeout
 * @author liyanqing14
 * @since 0.33.3
 */
 public class ForwardingTimeout <: Timeout {
    
    /**
     * let member delegate type is Timeout
     * @since 0.33.3
     */
    private var assignment: Timeout = Timeout()

     /**
     * The Function is ForwardingTimeout
     *
     * @param delegate of Timeout
     *
     * @since 0.33.3
     */
    public init(assignment: Timeout){
        this.assignment = assignment
    }

     /**
     * The Function is getDelegate
     *
     * @return Type of Timeout
     * @since 0.33.3
     */
    public func delegate():Timeout{
        return assignment
    }

    /**
     * The Function is setDelegate
     *
     * @param delegate of Timeout
     *
     * @return Type of ForwardingTimeout
     * @since 0.33.3
     */
    public func  setDelegate(assignment: Timeout):ForwardingTimeout{
        this.assignment = assignment
    return this    
    }

    /**
     * The Function is timeout
     *
     * @param timeout of Int64
     *
     * @return Type of Timeout
     * @since 0.33.3
     */
    public override func timeout(timeout: Int64):Timeout { //unit: TimeUnit 
        let thi =  assignment.timeout(timeout)
        return thi
    }

    /**
     * The Function is timeoutNanos
     *
     * @return Type of Int64
     * @since 0.33.3
     */
    public override func timeoutNanos(): Int64{
        return assignment.timeoutNanos()
    }

    /**
     * The Function is hasDeadline
     *
     * @return Type of Bool
     * @since 0.33.3
     */
    public override func hasDeadline():Bool{
        return assignment.hasDeadline()
    }

    /**
     * The Function is deadlineNanoTime
     *
     * @return Type of Int64
     * @since 0.33.3
     */
    public override func deadlineNanoTime():Int64 {
    return assignment.deadlineNanoTime();
    }

    /**
     * The Function is deadlineNanoTime
     *
     * @param deadlineNanoTime of Int64
     *
     * @return Type of Timeout
     * @since 0.33.3
     */
    public override func deadlineNanoTime(deadlineNanoTime: Int64):Timeout {
    return assignment.deadlineNanoTime(deadlineNanoTime);
    }

    /**
     * The Function is clearTimeout
     *
     * @return Type of Timeout
     * @since 0.33.3
     */
    public override func clearTimeout(): Timeout {
    return assignment.clearTimeout();
    }

    /**
     * The Function is clearDeadline
     *
     * @return Type of Timeout
     * @since 0.33.3
     */
    public override func clearDeadline(): Timeout {
    return assignment.clearDeadline();
    }

    /**
     * The Function is throwIfReached
     *
     * @since 0.33.3
     */
    public override func throwIfReached(): Unit{
    assignment.throwIfReached();
    }
 }