/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2022-2024. All rights resvered.
 */
package ohos_app_cangjie_OkRequest.okio

public func ArrayCopy(src: Array<Byte>, srcPos: Int64, dest: Array<Byte>, destPos: Int64, length: Int64) {
    if ((srcPos | destPos | length) < 0) {
        throw IndexOutOfBoundsException()
    }
    if (destPos > dest.size) {
        throw IndexOutOfBoundsException()
    }
    src.copyTo(dest, srcPos, destPos, length)
}

public func wrap(arrays: Array<UInt8>): ByteBuffer {
    try{
        return ByteBuffer(-1, 0, arrays.size, arrays.size, arrays, 0)
    } catch (ex: IllegalArgumentException) {
        throw IndexOutOfBoundsException()
    }
}

public func wrap(arrays: Array<UInt8>, offset: Int64, length: Int64): ByteBuffer {
    try{
        return ByteBuffer(-1, offset, offset+length, length, arrays, 0)
    } catch (ex: IllegalArgumentException) {
        throw IndexOutOfBoundsException()
    }
}


public class ByteBuffer  {
    let hb: Array<Byte> 
    var mar_: Int64 = -1
    var pos_: Int64 = 0
    var lim_: Int64
    var capa_: Int64
    let off_: Int64
    public mut prop limit: Int64 {
        get() {
            lim_
        }
        set(newLimits) {
            lim_ = newLimits
            if (pos_ > lim_) {pos_ = lim_}
            if (mar_ > lim_) {mar_ = -1}
        }   
    }

    public prop array: Array<Byte> {
        get() {
            this.hb
        }
    }
    
    public prop offset: Int64 {
        get() {
            off_
        }
    }
    
    public mut prop position: Int64 {
        get() {
            pos_
        }
        set(value) {
            if (value > lim_ || value < 0) {
                throw IllegalArgumentException("newPosition")
            }
            if (mar_ > pos_) {
                mar_ = -1
            }
            pos_ = value
        }   
    }

    public prop capa: Int64 {
        get() {
            capa_
        }
    }
    public prop remaining: Int64 {
        get() {
            lim_ - pos_
        }
    }

    ByteBuffer (marks: Int64, position: Int64, limits: Int64, capacity: Int64, hbs: Array<Byte>, offsets: Int64) {
        this.mar_ = marks
        this.pos_ = position
        this.lim_ = limits 
        this.capa_ = capacity
        this.hb = hbs
        this.off_ = offsets
    }
    
    public func mark(): Unit {
        mar_ = pos_
    }

    public func put(src: Array<Byte>, offsets: Int64, length: Int64): Unit {
        ArrayCopy(src, offsets, hb, pos_ + off_, length)
        pos_ = pos_ + length
    }
}
