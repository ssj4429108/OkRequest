/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2022-2024. All rights resvered.
 */

/**
 * @file
 * The file declars the GzipSource class.
 */

package ohos_app_cangjie_OkRequest.okio

public class GzipSource <: Source {

    private static var FHCRC: Int8 = 1
    private static var FEXTRA: Int8 = 2
    private static var FNAME: Int8 = 3
    private static var FCOMMENT: Int8 = 4

    private static var SECTION_HEADER: Int8 = 0
    private static var SECTION_BODY: Int8 = 1
    private static var SECTION_TRAILER: Int8 = 2
    private static var SECTION_DONE: Int8 = 3

    private var section: Int8 = SECTION_HEADER
    private var source: BufferedSource
    private var inflaterSource: InflaterSource

    /**
     * The Function is init constructor
     *
     * @since 0.34.3
     */
    public init(source:Source){
        this.source = Okio.buffer(source)
        this.inflaterSource = InflaterSource(source)
    }

    /**
     * The Function is read
     *
     * @param sink of Buffer
     * @param byteCount of Int64
     *
     * @return Type of Int64
     * @since 0.34.3
     */
    public func read(sink: Buffer,byteCount: Int64): Int64{
        if(byteCount < 0){
            throw IllegalArgumentException("byteCount < 0:${byteCount}")
        }
        if(byteCount == 0){
            return 0
        }
        if(section == SECTION_HEADER){
            section = SECTION_BODY
        }
        if(section == SECTION_BODY){
            let offest: Int64 = sink.size
            let result: Int64 = inflaterSource.read(sink , byteCount)
            if(result != -1){

                return result
            }
            section = SECTION_TRAILER
        }
        if(section == SECTION_TRAILER){

            let section = SECTION_DONE
           
        }
        return -1
    }
    
    /**
     * The Function is timeout
     *
     * @return Type of Timeout
     * @since 0.34.3
     */
    public override func timeout(): Timeout{
        return source.timeout()
    }

    /**
     * The Function is close
     *
     * @return Type of Unit
     * @since 0.34.3
     */
    public override func close(): Unit{     
        inflaterSource.close()
    }

    /**
     * The Function is isClosed
     *
     *@return Type of Bool
     * @since 0.34.3
     */
    public override func isClosed(): Bool {
        return source.isClosed()
    } 

    /**
     * The Function is toString
     *
     *@return Type of String
     * @since 0.34.3
     */
    public override func toString():String{
        return source.toString()
    } 
     
    public func buffer(): BufferedSource {
        return source
    }
}
