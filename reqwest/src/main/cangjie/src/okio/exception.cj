/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2022-2024. All rights resvered.
 */

/**
 * @file
 * The file declars the AssertionException class.
 */


package ohos_app_cangjie_OkRequest.okio

/**
 * The class is AssertionException inherited from Exception
 * @author liyanqing14
 * @since 0.32.5
 */
public class AssertionException <: Exception {
    /**
     * The Function is init constructor
     *
     * @since 0.32.5
     */
    public init(){
        this("")
    }
    /**
     * The Function is init constructor
     *
     * @param string of String
     * @since 0.32.5
     */
    public init(string: String) {
        super("AssertionException: \n${string}")
    }
}
/**
 * The class is ArrayIndexOutOfBoundsException inherited from Exception
 * @author liyanqing14
 * @since 0.32.5
 */
public class ArrayIndexOutOfBoundsException <: Exception {
    /**
     * The Function is init constructor
     *
     * @since 0.32.5
     */
    public init(){
        this("")
    }
    /**
     * The Function is init constructor
     *
     * @param string of String
     * @since 0.32.5
     */
    public init(string: String) {
        super("ArrayIndexOutOfBoundsException: \n${string}")
    }
}
/**
 * The class is EOFException inherited from Exception
 * @author liyanqing14
 * @since 0.32.5
 */
public class EOFException <: Exception {
    /**
     * The Function is init constructor
     *
     * @since 0.32.5
     */
    public init(){
        this("")
    }
    /**
     * The Function is init constructor
     *
     * @param string of String
     * @since 0.32.5
     */
    public init(string: String) {
        super("EOFException: \n${string}")
    }
}
/**
 * The class is InterruptedException inherited from Exception
 * @author liyanqing14
 * @since 0.32.5
 */
public class InterruptedException <: Exception {
    /**
     * The Function is init constructor
     *
     * @since 0.32.5
     */
    public init(){
        this("")
    }
    /**
     * The Function is init constructor
     *
     * @param string of String
     * @since 0.32.5
     */
    public init(string: String) {
        super("InterruptedException: \n${string}")
    }
}

/**
 * The class is NumberFormatException inherited from Exception
 * @author liyanqing14
 * @since 0.32.5
 */
public class NumberFormatException <: Exception {
    /**
     * The Function is init constructor
     *
     * @since 0.32.5
     */
    public init(){
        this("")
    }
    /**
     * The Function is init constructor
     *
     * @param string of String
     * @since 0.32.5
     */
    public init(string: String) {
        super("NumberFormatException: \n${string}")
    }
}
