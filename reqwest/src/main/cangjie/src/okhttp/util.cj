/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2022-2024. All rights resvered.
 */

/**
 * @file
 * The file declares the Util class.
 */

package ohos_app_cangjie_OkRequest.okhttp

internal import compress.zlib.*
internal import encoding.hex.*
internal import encoding.url.*
internal import net.http.*
internal import net.http.CookieJar as HttpCookieJar
internal import net.tls.*
internal import std.collection.*
internal import std.convert.*
internal import std.format.*
internal import std.fs.*
internal import std.io.*
internal import std.log.*
internal import std.math.*
internal import std.random.*
internal import std.regex.*
internal import std.socket.*
internal import std.sync.*
internal import std.time.*
internal import std.unicode.*
internal import crypto.crypto.*

let METHOD_GET = "GET"

/**
 * The class is Util
 * @author guo_tingtingtekla,luoyukai4
 * @since 0.29.3
 */
class Util {
    private static let VERIFY_AS_IP_ADDRESS = "([0-9a-fA-F]*:[0-9a-fA-F:.]*)|([\\d.]+)"

    /**
     * The Function is closeQuietly
     *
     * @param socket of Option<Socket>
     * @since 0.29.3
     */
    static func closeQuietly<T>(socket: Option<T>): Unit where T <: Resource {
        match (socket) {
            case Some(s) => try {
                if (!s.isClosed()) {
                    s.close()
                }
            } catch (ignored: Exception) {
                throw ignored
            }
            case None => ()
        }
    }

    /**
     * The Function is sameConnection
     *
     * @param a of URL
     * @param b of URL
     *
     * @return Type of Bool
     * @since 0.29.3
     */
    static func sameConnection(a: URL, b: URL): Bool {
        return a.hostName == b.hostName && a.port == b.port && a.scheme == b.scheme
    }

    static func skipUntil(input: String, pos: Int64, characters: String): Int64 {
        var posi: Int64 = pos

        while (posi < input.size) {
            let res: Int64 = characters.indexOf(input[Int64(posi)]) ?? -1
            if (res != -1) {
                break
            }
            posi++
        }

        return posi
    }

    static func skipWhitespace(input: String, pos: Int64): Int64 {
        var posi: Int64 = pos

        while (posi < input.size) {
            let c = input[posi]
            if (c != b' ' && c != b'\t') {
                break
            }
            posi++
        }

        return posi
    }

    static func parseSeconds(value: String, defaultValue: Int64): Int64 {
        try {
            let seconds: Int32 = Int32.parse(value)
            if (seconds > Int32.Max) {
                return Int64(Int32.Max)
            } else if (seconds < 0) {
                return 0
            } else {
                return Int64(seconds)
            }
        } catch (e: Exception) {
            return defaultValue
        }
    }

    static func verifyAsIpAddress(host: String): Bool {
        match (Regex(VERIFY_AS_IP_ADDRESS).matches(host)) {
            case Some(_) => return true
            case None => return false
        }
    }
}

func addLenient(header: Header, line: String) {
    match (line.indexOf(":", 1)) {
        case Some(index) => header.add(line.substring(0, index), line.substring(index + 1).trim())
        case None => if (!line.startsWith(":")) {
            header.add("", line)
        } else {
            throw ProtocolException("Unexpected header: ${line}")
        }
    }
}

/*
 * The Function is receiveHeaders
 *
 * @param cookieJar of CookieJar
 * @param url of URL
 * @param header of Header
 *
 * @return Type of Unit
 * @since 0.29.3
 */
func receiveHeaders(cookieJar: CookieJar, url: URL, headers: Header): Unit {
    match (cookieJar) {
        case _: NoCookieJar => return
        case _ => ()
    }

    let cookies: ArrayList<Cookie> = CookieUtil.parseAll(url, headers)

    if (cookies.isEmpty()) {
        return
    }
    cookieJar.saveFromResponse(url, cookies.toArray())
}

func disCard(source: Source): Bool {
    try {
        let arr = ByteArrayStream()
        while (source.read(arr, 4096) != -1) {
            arr.clear()
        }
        return true
    } catch (e: SocketTimeoutException) {
        return false
    }
}

func equalsIgnoreCase(left: String, right: String): Bool {
    return left.toUpper() == right.toUpper()
}

func UInt64ToHexString(n: UInt64): Array<Byte> {
    var num: UInt64 = n
    var arrSize: Int64 = 0

    for (_ in 0..16) {
        if (num > 0) {
            arrSize++
            num = num >> 4
        } else {
            break
        }
    }

    var arr = Array<Byte>(arrSize, item: UInt8(CHAR_ZERO))
    var mask: UInt64 = 0x0f
    num = n

    for (i in arrSize - 1..-1 : -1) {
        if (num > 0) {
            var item = num & mask
            arr[i] = UInt64ToHex[Int64(item)]
            num = num >> 4
        } else {
            break
        }
    }
    return arr
}

func HexStringToUInt64(arr: Array<Byte>): Option<UInt64> {
    var arrSize = arr.size
    var num: UInt64 = 0

    for (i in 0..arrSize) {
        var b = arr[i]
        if (b'0' <= b && b <= b'9') {
            b = b - b'0'
        } else if (b'a' <= b && b <= b'f') {
            b = b - (b'a' - 10)
        } else if (b'A' <= b && b <= b'F') {
            b = b - (b'A' - 10)
        } else {
            return None
        }
        num = num * 16 + UInt64(b)
    }
    return Some(num)
}

func has<T>(op: Option<T>): Bool {
    match (op) {
        case Some(_) => return true
        case None => return false
    }
}

extend Int64 {
    operator func >=(right: UInt16): Bool {
        this >= Int64(right)
    }
    operator func !=(right: UInt16): Bool {
        this != Int64(right)
    }
    operator func ==(right: UInt16): Bool {
        this == Int64(right)
    }
    operator func <(right: UInt16): Bool {
        this < Int64(right)
    }
}

extend Cookie {
    prop name: String {
        get() {
            this.cookieName
        }
    }
    prop value: String {
        get() {
            this.cookieValue
        }
    }
}

extend Header {
    public func clone(): Header {
        let dest = Header()
        for ((k, v) in this) {
            dest.set(k, v)
        }
        dest
    }
    public func remove(k: String): Unit {
        this.del(k)
    }
    public func getString(k: String): ?String {
        match (this.get(k)) {
            case Some(v) => v |> collectString<String>(delimiter: "; ")
            case _ => None
        }
    }
    public func getAll(k: String): ArrayList<String> {
        this.get(k) ?? this.get(k.toLower()) ?? ArrayList()
    }
}

public class Header <: Iterable<(String, ArrayList<String>)> {
    let fields = HashMap<String, ArrayList<String>>()
    let httpHeaders = HttpHeaders()

    public init() {}
    init(fields: Array<HeaderField>) {
        for (f in fields) {
            this.set(f.name, toValueArr(f.value))
        }
    }
    private func toValueArr(value: String): ArrayList<String> {
        value.split(";") |> map {s: String => s.trim()} |> collectArrayList
    }
    public func add(name: String, value: String): Unit {
        if (name.startsWith(":")) {
            let list = fields.get(name) ?? ArrayList<String>()
            list.append(value.trim())
            this.fields.put(name.toLower(), list)
        } else {
            httpHeaders.add(name, value)
        }
    }
    public func set(name: String, value: ArrayList<String>): Unit {
        if (name.startsWith(":")) {
            this.fields.put(name.toLower(), value)
        } else {
            httpHeaders.del(name)
            for (v in value) {
                httpHeaders.add(name, v)
            }
        }
    }
    public func get(name: String): ?ArrayList<String> {
        let arr = httpHeaders.get(name)
        if (arr.size != 0) {
            return arr |> collectArrayList
        }
        return fields.get(name)
    }
    public func del(name: String): Unit {
        fields.remove(name)
        httpHeaders.del(name)
    }
    public func iterator(): Iterator<(String, ArrayList<String>)> {
        httpHeaders |>
            map<(String, Collection<String>), (String, ArrayList<String>)> {kv => (kv[0], kv[1] |> collectArrayList)} |>
            concat(fields)
    }
}

foreign func htons(port: UInt16): UInt16
public func portTrans(port: UInt16): UInt16 {
    // unsafe { htons(port) }
    port
}

let LOG: SimpleLogger = SimpleLogger()


extend String {
    func equals(s: String): Bool {
        this == s
    }
    func toUtf8Array(): Array<UInt8> {
        this.toArray()
    }
    func substring(start: Int64, size: Int64): String {
        this[start..start + size]
    }
    func substring(start: Int64): String {
        this[start..]
    }
    func contains(char: Rune): Bool {
        this.contains(char.toString())
    }
    func indexOf(char: Rune): ?Int64 {
        this.indexOf(char.toString())
    }
    func indexOf(char: Rune, begin: Int64): ?Int64 {
        this.indexOf(char.toString(), begin)
    }
}
extend UInt8 {
    operator func ==(char: Rune): Bool {
        UInt32(this) == UInt32(char)
    }
    operator func !=(char: Rune): Bool {
        UInt32(this) != UInt32(char)
    }
    operator func <(char: Rune): Bool {
        UInt32(this) < UInt32(char)
    }
    operator func <=(char: Rune): Bool {
        UInt32(this) <= UInt32(char)
    }
    operator func >=(char: Rune): Bool {
        UInt32(this) >= UInt32(char)
    }
}
