/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2022-2024. All rights resvered.
 */

/**
 * @file The file declars the HeaderField class.
 */

package ohos_app_cangjie_reqwest.okhttp

/**
 * The type Header field.
 */
struct HeaderField {
    var name: String
    var value: String
    var sensitive: Bool

    /**
     * Instantiates a new Init.
     *
     * @param n of String
     * @param v of String
     * @param s of Bool
     * @since 0.35.6
     */
    init(name: String, value: String, sensitive: Bool) {
        this.name = name
        this.value = value
        this.sensitive = sensitive
    }

    /**
     * Instantiates a new Init.
     *
     * @param n of String
     * @param v of String
     * @since 0.35.6
     */
    init(name: String, value: String) {
        this.name = name
        this.value = value
        this.sensitive = false
    }

    /**
     * Instantiates a new Init.
     *
     * @param n of String
     * @since 0.35.6
     */
    init(name: String) {
        this.name = name
        this.value = ""
        this.sensitive = false
    }

    /**
     * Size func.
     *
     * @return Type of Int64
     * @since 0.35.6
     */
    func size(): Int64 {
        return this.name.size + this.value.size + CONST_32_I64
    }
}

/**
 * The type Header static table.
 */
class HeaderStaticTable {
    static let capacity: Int64 = 61
    private static let staticTable: Array<HeaderField> = [
        /* 1 */ HeaderField(":authority"),
        /* 2 */ HeaderField(":method", "GET"),
        /* 3 */ HeaderField(":method", "POST"),
        /* 4 */ HeaderField(":path", "/"),
        /* 5 */ HeaderField(":path", "/index.html"),
        /* 6 */ HeaderField(":scheme", "http"),
        /* 7 */ HeaderField(":scheme", "https"),
        /* 8 */ HeaderField(":status", "200"),
        /* 9 */ HeaderField(":status", "204"),
        /* 10 */ HeaderField(":status", "206"),
        /* 11 */ HeaderField(":status", "304"),
        /* 12 */ HeaderField(":status", "400"),
        /* 13 */ HeaderField(":status", "404"),
        /* 14 */ HeaderField(":status", "500"),
        /* 15 */ HeaderField("accept-charset"),
        /* 16 */ HeaderField("accept-encoding", "gzip, deflate"),
        /* 17 */ HeaderField("accept-language"),
        /* 18 */ HeaderField("accept-ranges"),
        /* 19 */ HeaderField("accept"),
        /* 20 */ HeaderField("access-control-allow-origin"),
        /* 21 */ HeaderField("age"),
        /* 22 */ HeaderField("allow"),
        /* 23 */ HeaderField("authorization"),
        /* 24 */ HeaderField("cache-control"),
        /* 25 */ HeaderField("content-disposition"),
        /* 26 */ HeaderField("content-encoding"),
        /* 27 */ HeaderField("content-language"),
        /* 28 */ HeaderField("content-length"),
        /* 29 */ HeaderField("content-location"),
        /* 30 */ HeaderField("content-range"),
        /* 31 */ HeaderField("content-type"),
        /* 32 */ HeaderField("cookie"),
        /* 33 */ HeaderField("date"),
        /* 34 */ HeaderField("etag"),
        /* 35 */ HeaderField("expect"),
        /* 36 */ HeaderField("expires"),
        /* 37 */ HeaderField("from"),
        /* 38 */ HeaderField("host"),
        /* 39 */ HeaderField("if-match"),
        /* 40 */ HeaderField("if-modified-since"),
        /* 41 */ HeaderField("if-none-match"),
        /* 42 */ HeaderField("if-range"),
        /* 43 */ HeaderField("if-unmodified-since"),
        /* 44 */ HeaderField("last-modified"),
        /* 45 */ HeaderField("link"),
        /* 46 */ HeaderField("location"),
        /* 47 */ HeaderField("max-forwards"),
        /* 48 */ HeaderField("proxy-authenticate"),
        /* 49 */ HeaderField("proxy-authorization"),
        /* 50 */ HeaderField("range"),
        /* 51 */ HeaderField("referer"),
        /* 52 */ HeaderField("refresh"),
        /* 53 */ HeaderField("retry-after"),
        /* 54 */ HeaderField("server"),
        /* 55 */ HeaderField("set-cookie"),
        /* 56 */ HeaderField("strict-transport-security"),
        /* 57 */ HeaderField("transfer-encoding"),
        /* 58 */ HeaderField("user-agent"),
        /* 59 */ HeaderField("vary"),
        /* 60 */ HeaderField("via"),
        /* 61 */ HeaderField("www-authenticate")
    ]

    private static let hashStaticTable: HashMap<String, Array<Int64>> = HashMap<String, Array<Int64>>(
        /* 1 */ [
            (":authority", [1]),
            /* 2 */ (":method", [2, 3]),
            /* 4 */ (":path", [4, 5]),
            /* 6 */ (":scheme", [6, 7]),
            /* 8 */ (":status", [8, 9, 10, 11, 12, 13, 14]),
            /* 15 */ ("accept-charset", [15]),
            /* 16 */ ("accept-encoding", [16]),
            /* 17 */ ("accept-language", [17]),
            /* 18 */ ("accept-ranges", [18]),
            /* 19 */ ("accept", [19]),
            /* 20 */ ("access-control-allow-origin", [20]),
            /* 21 */ ("age", [21]),
            /* 22 */ ("allow", [22]),
            /* 23 */ ("authorization", [23]),
            /* 24 */ ("cache-control", [24]),
            /* 25 */ ("content-disposition", [25]),
            /* 26 */ ("content-encoding", [26]),
            /* 27 */ ("content-language", [27]),
            /* 28 */ ("content-length", [28]),
            /* 29 */ ("content-location", [29]),
            /* 30 */ ("content-range", [30]),
            /* 31 */ ("content-type", [31]),
            /* 32 */ ("cookie", [32]),
            /* 33 */ ("date", [33]),
            /* 34 */ ("etag", [34]),
            /* 35 */ ("expect", [35]),
            /* 36 */ ("expires", [36]),
            /* 37 */ ("from", [37]),
            /* 38 */ ("host", [38]),
            /* 39 */ ("if-match", [39]),
            /* 40 */ ("if-modified-since", [40]),
            /* 41 */ ("if-none-match", [41]),
            /* 42 */ ("if-range", [42]),
            /* 43 */ ("if-unmodified-since", [43]),
            /* 44 */ ("last-modified", [44]),
            /* 45 */ ("link", [45]),
            /* 46 */ ("location", [46]),
            /* 47 */ ("max-forwards", [47]),
            /* 48 */ ("proxy-authenticate", [48]),
            /* 49 */ ("proxy-authorization", [49]),
            /* 50 */ ("range", [50]),
            /* 51 */ ("referer", [51]),
            /* 52 */ ("refresh", [52]),
            /* 53 */ ("retry-after", [53]),
            /* 54 */ ("server", [54]),
            /* 55 */ ("set-cookie", [55]),
            /* 56 */ ("strict-transport-security", [56]),
            /* 57 */ ("transfer-encoding", [57]),
            /* 58 */ ("user-agent", [58]),
            /* 59 */ ("vary", [59]),
            /* 60 */ ("via", [60]),
            /* 61 */ ("www-authenticate", [61])
        ]
    )

    /**
     * Get index func.
     *
     * @return the HeaderField
     */
    static func getIndex(index: Int64): HeaderField {
        if (index <= 0 || index > staticTable.size) {
            throw IndexOutOfBoundsException()
        }
        return staticTable[index - 1]
    }

    /**
     * Search full func.
     *
     * @return the Int64 * Int64
     */
    public static func searchFull(f: HeaderField): (Int64, Int64) {
        match (hashStaticTable.get(f.name)) {
            case Some(v) =>
                for (i in 0..v.size where f.value == staticTable[v[i] - 1].value) {
                    return (v[i], v[i])
                }
                return (v[0], -1)
            case None => return (-1, -1)
        }
    }
}

let MAX_INT: Int64 = 0xFFFFFFFF
let MIN_INT: Int64 = 0

/**
 * The type Dynamic tables.
 *
 * Dynamic table size = (sum of bytes per Header +32) * number of key-value pairs
 */
class DynamicTables {
    protected var dynamicArray: Array<(Option<HeaderField>)>
    protected static let NULL: Option<HeaderField> = None
    protected var tail: Int64
    protected var head: Int64
    protected var myCapacity: Int64
    protected var hashDynamicTable: HashMap<String, ArrayList<Int64>> // <name, indexs>
    protected var mySize: Int64

    /**
     * Instantiates a new Init.
     */
    init(bs: Int64) {
        if (bs < MIN_INT || bs > MAX_INT) {
            throw IndexOutOfBoundsException("invalid value: ${bs}")
        }
        this.myCapacity = bs
        var maxEntries: Int64 = bs / CONST_32_I64
        if ((bs - CONST_32_I64 * maxEntries) != 0) {
            maxEntries++
        }
        this.dynamicArray = Array<Option<HeaderField>>(maxEntries, item: NULL)
        this.tail = 0
        this.head = 0
        this.mySize = 0
        this.hashDynamicTable = HashMap<String, ArrayList<Int64>>()
        this.myCapacity = bs
    }

    /**
     * Size func.
     *
     * @return the Int64
     */
    func size(): Int64 {
        return mySize
    }

    /**
     * Capacity func.
     *
     * @return the Int64
     */
    func capacity(): Int64 {
        return myCapacity
    }

    /**
     * Length func.
     *
     * @return the Int64
     */
    func length(): Int64 {
        return if (this.head < this.tail) {
            dynamicArray.size + head - tail
        } else {
            head - tail
        }
    }

    /**
     * Add func.
     * It is not an error to try to add an entry larger than the maximum size
     * Attempting to add an entry larger than the maximum size causes the table to
     * empty all existing entries and results in an empty table.
     *
     * @return the Unit
     */
    public func add(header: HeaderField): Unit {
        let headerSize: Int64 = header.size()
        if (headerSize > this.myCapacity) {
            clear()
            return
        }
        while (this.myCapacity - size() < headerSize) {
            remove()
        }
        this.dynamicArray[head] = header
        match (this.hashDynamicTable.get(header.name)) {
            case Some(v) => v.append(head)
            case None =>
                let list = ArrayList<Int64>()
                list.append(head)
                hashDynamicTable[header.name] = list
        }
        this.head++
        this.mySize += headerSize
        if (this.head == dynamicArray.size) {
            this.head = 0
        }
    }

    /**
     * Get entry func.
     *
     * @return the HeaderField
     */
    public func getEntry(ind: Int64): HeaderField {
        let index = ind - 62
        if (index < 0 || index > length() || this.length() == 0) {
            throw IndexOutOfBoundsException()
        }
        let i: Int64 = this.head - 1 - index
        if (i < 0) {
            return dynamicArray[i + dynamicArray.size].getOrThrow()
        } else if (i >= 0) {
            return dynamicArray[i].getOrThrow()
        }
        throw NoneValueException()
    }

    /**
     * Remove func.
     *
     * @return the Option<HeaderField>
     */
    public func remove(): Option<HeaderField> {
        match (dynamicArray[this.tail]) {
            case None => return None
            case Some(v) =>
                mySize = mySize - v.size()
                let list = hashDynamicTable[v.name]
                var index = 0
                for (index in 0..list.size) {
                    if (list.size == index) {
                        break
                    }
                    //index ++
                }
                if (list.size == 1) {
                    hashDynamicTable.remove(v.name)
                } else {
                    list.remove(index)
                }
                dynamicArray[this.tail] = NULL
                tail++
                if (tail == this.dynamicArray.size) {
                    tail = 0
                }
                return v
        }
    }

    /**
     * Clear func.
     *
     * @return the Unit
     */
    public func clear(): Unit {
        while (this.tail != this.head) {
            this.dynamicArray[this.tail] = NULL
            this.tail++
            if (this.tail == this.dynamicArray.size) {
                this.tail = 0
            }
        }
        this.head = 0
        this.tail = 0
        this.mySize = 0
        this.hashDynamicTable = HashMap<String, ArrayList<Int64>>()
    }

    /**
     * Set capacity func.
     *
     * @return the Bool
     */
    /* size <= 0xFFFF_FFFF */
    public func setCapacity(s: UInt32): Bool {
        let newSize: Int64 = Int64(s)
        if (newSize == myCapacity) {
            return false
        }
        this.myCapacity = newSize
        if (newSize == 0) {
            clear()
            return false
        } else {
            while (this.mySize > newSize) {
                remove()
            }
        }

        /* set size*/
        var maxEntries: Int64 = newSize / CONST_32_I64
        if ((newSize - CONST_32_I64 * maxEntries) != 0) {
            maxEntries++
        }
        if (this.dynamicArray.size == maxEntries) {
            return false
        }
        let newFields: Array<Option<HeaderField>> = Array<Option<HeaderField>>(maxEntries, item: NULL)
        hashDynamicTable.clear()
        let len: Int64 = length()
        var cur: Int64 = tail
        for (i in 0..len) {
            newFields[i] = dynamicArray[cur]
            let name = dynamicArray[cur].getOrThrow().name
            match (hashDynamicTable.get(name)) {
                case Some(v) => v.append(i)
                case None =>
                    let list = ArrayList<Int64>()
                    list.append(i)
                    hashDynamicTable[name] = list
            }
            cur++
            if (cur == this.dynamicArray.size) {
                cur = 0 // ring array set to 0 index
            }
        }
        this.tail = 0
        this.head = tail + len
        this.dynamicArray = newFields
        return true
    }

    /**
     * Search func.
     *
     * @return the Int64*Int64*Bool
     */
    func search(f: HeaderField): (Int64, Int64) {
        let offset = if (this.tail > head) {
            dynamicArray.size - tail + head
        } else {
            head - tail
        }
        match (hashDynamicTable.get(f.name)) {
            case Some(v) =>
                for (i in 0..v.size) {
                    let field = dynamicArray[i].getOrThrow()
                    if (f.name.equals(field.name) && f.value.equals(field.value)) {
                        return (offset - i + 61, offset - i + 61)
                    }
                }
                return (offset - v[0] + 61, -1)
            case None => return (-1, -1)
        }
    }
}
