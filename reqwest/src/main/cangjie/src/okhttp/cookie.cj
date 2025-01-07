/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2022-2024. All rights resvered.
 */

/**
 * @file
 * The file declares the Cookie class.
 */

package ohos_app_cangjie_OkRequest.okhttp

let BIG: Int64 = 0xFFFFFF

public class CookieUtil {
    private static let TIME_PATTERN = "(\\d{1,2}):(\\d{1,2}):(\\d{1,2})[^\\d]*"
    private static let DAY_OF_MONTH_PATTERN = "(\\d{1,2})[^\\d]*"
    private static let MONTH_PATTERN = "(?i)(jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec).*"
    private static let YEAR_PATTERN = "(\\d{2,4})[^\\d]*"

    static func delimiterOffset(input: String, pos: Int64, limit: Int64, delimiter: Rune): Int64 {
        for (i in pos..limit) {
            if (input[i] == delimiter) {
                return i
            }
        }

        return limit
    }

    public static func parseAll(url: URL, headers: Header): ArrayList<Cookie> {
        let values: ArrayList<String>

        try {
            values = headers.getAll("Set-Cookie")
        } catch (e: NoneValueException) {
            return ArrayList<Cookie>()
        }

        let cookies = ArrayList<Cookie>()

        for (i in 0..values.size) {
            let cookie = parse(url, values[i])
            match (cookie) {
                case None => continue
                case Some(c) => cookies.append(c)
            }
        }

        return cookies
    }

    public static func parse(url: URL, setCookie: String): Option<Cookie> {
        var pos = 0
        let limit = setCookie.size
        let cookiePairEnd = delimiterOffset(setCookie, pos, limit, r';')
        let pairEqualsSign = delimiterOffset(setCookie, pos, limit, r'=')

        if (cookiePairEnd == pairEqualsSign) {
            return None
        }

        let cookieName = trimSubstring(setCookie, pos, pairEqualsSign)

        if (cookieName.size == 0) {
            return None
        }
        if (indexOfControlOrNonAscii(cookieName) != -1) {
            return None
        }

        let cookieValue = trimSubstring(setCookie, pairEqualsSign + 1, cookiePairEnd)

        if (indexOfControlOrNonAscii(cookieValue) != -1) {
            return None
        }

        var expiresAt: DateTime = DateTime.of(
            year: 2260,
            month: Month.of(12),
            dayOfMonth: 31,
            hour: 23,
            minute: 59,
            second: 59,
            timeZone: TimeZone.load("GMT")
        )
        var deltaSeconds = -1
        var domain = ""
        var path = ""
        var secureOnly = false
        var httpOnly = false
        var rawExpires = ""
        pos = cookiePairEnd + 1

        while (pos < limit) {
            let attributePairEnd = delimiterOffset(setCookie, pos, limit, r';')
            let attributeEqualsSign = delimiterOffset(setCookie, pos, attributePairEnd, r'=')
            let attributeName = trimSubstring(setCookie, pos, attributeEqualsSign)
            var attributeValue = ""
            if (attributeEqualsSign < attributePairEnd) {
                attributeValue = trimSubstring(setCookie, attributeEqualsSign + 1, attributePairEnd)
            }
            if (equalsIgnoreCase(attributeName, "expires")) {
                try {
                    rawExpires = attributeValue
                    expiresAt = parseExpires(attributeValue, 0, attributeValue.size)
                } catch (e: Exception) {
                    // Ignore this attribute
                }
            } else if (equalsIgnoreCase(attributeName, "max-age")) {
                try {
                    deltaSeconds = parseMaxAge(attributeValue)
                } catch (e: Exception) {
                    // Ignore this attribute
                }
            } else if (equalsIgnoreCase(attributeName, "domain")) {
                try {
                    domain = parseDomain(attributeValue)
                } catch (e: Exception) {
                    // Ignore this attribute, it isn't recognizable as a domain.
                }
            } else if (equalsIgnoreCase(attributeName, "path")) {
                path = attributeValue
            } else if (equalsIgnoreCase(attributeName, "secure")) {
                secureOnly = true
            } else if (equalsIgnoreCase(attributeName, "httponly")) {
                httpOnly = true
            }
            pos = attributePairEnd + 1
        }
        expiresAt = checkExpiresAt(getTimeStamp(expiresAt), deltaSeconds)

        let urlHost = url.hostName

        if (domain == "") {
            // domain = urlHost
        } else if (!domainMatch(urlHost, domain)) {
            return None
        }

        if (path == "" || !path.startsWith("/")) {
            let encodedPath = url.rawPath
            let lastSlash = encodedPath.lastIndexOf("/") ?? 0
            path = if (lastSlash != 0) {
                encodedPath.substring(0, lastSlash)
            } else {
                "/"
            }
        }

        let cookieMaxAge: ?Int64 = match (deltaSeconds) {
            case -1 => None
            case _ => deltaSeconds
        }
        return Cookie(
            cookieName,
            cookieValue,
            path: path,
            domain: domain,
            expires: expiresAt,
            maxAge: cookieMaxAge,
            secure: secureOnly,
            httpOnly: httpOnly
        )
    }

    static func trimSubstring(str: String, pos: Int64, limit: Int64): String {
        return str.substring(pos, limit - pos).trim()
    }

    private static func domainMatch(urlHost: String, domain: String) {
        if (urlHost == domain) {
            return true
        }
        if (urlHost[0] == b'[' && urlHost[urlHost.size - 1] == b']' && urlHost[1..urlHost.size - 1] == domain) {
            return true
        }
        if (urlHost.endsWith(domain) && urlHost[urlHost.size - domain.size - 1] == b'.') {
            if (!Util.verifyAsIpAddress(urlHost)) {
                return true
            }
        }

        return false
    }

    static func indexOfControlOrNonAscii(input: String): Int64 {
        let arr = input.toRuneArray()
        for (i in 0..arr.size) {
            let c = arr[i]
            if ((c <= r'\u{001f}' || c >= r'\u{007f}') || ##"(),/:;<=>?@[\]{}"##.contains(c.toString())) {
                return i
            }
        }

        return -1
    }

    @OverflowSaturating
    private static func checkExpiresAt(e: Int64, deltaSeconds: Int64): DateTime {
        var expiresAt = e

        if (deltaSeconds == Int64.Min) {
            expiresAt = Int64.Min
        } else if (deltaSeconds != -1) {
            let deltaMilliseconds = if (deltaSeconds <= Int64.Max / 1000) {
                deltaSeconds * 1000
            } else {
                Int64.Max
            }
            expiresAt = getTimeStamp(DateTime.now()) + deltaMilliseconds
        }
        return getTime(expiresAt)
    }

    private static func parseDomain(input: String): String {
        var s = input

        if (s.endsWith(".")) {
            throw IllegalArgumentException()
        }

        if (s.startsWith(".")) {
            s = s.substring(1)
        }

        let canonicalDomain = canonicalizeHost(s)
        if (canonicalDomain == "") {
            throw IllegalArgumentException()
        }

        return canonicalDomain
    }

    private static func canonicalizeHost(s: String): String {
        if (s.contains(':')) {
            let (_, _, err) = parseIPv6Zone(s)

            if (!err) {
                return s
            } else {
                throw IllegalArgumentException()
            }
        }

        return s
    }

    static func parseExpires(s: String, start: Int64, limit: Int64): DateTime {
        var pos = dateCharacterOffset(s, start, limit, false)
        var (hour, minute, second, dayOfMonth, month, year) = (-1, -1, -1, -1, -1, -1)
        let timeMatcher = Regex(TIME_PATTERN)
        let domMatcher = Regex(DAY_OF_MONTH_PATTERN)
        let monthMatcher = Regex(MONTH_PATTERN)
        let yearMatcher = Regex(YEAR_PATTERN)
        while (pos < limit) {
            let end = dateCharacterOffset(s, pos + 1, limit, true)
            let offString = s[pos..end]

            let ifMatchTime = matchTime(offString)
            let ifMatchDOM = matchDOM(offString)
            let ifMatchMonth = matchMonth(offString)
            let ifMatchYear = matchYear(offString)
            if (hour == -1 && ifMatchTime) {
                match (timeMatcher.matches(offString)) {
                    case Some(data) =>
                        hour = Int64.parse(data.matchStr(1))
                        minute = Int64.parse(data.matchStr(2))
                        second = Int64.parse(data.matchStr(3))
                    case None => ()
                }
            } else if (dayOfMonth == -1 && ifMatchDOM) {
                match (domMatcher.matches(s[pos..end])) {
                    case Some(data) => dayOfMonth = Int64.parse(data.matchStr(1))
                    case None => ()
                }
            } else if (month == -1 && ifMatchMonth) {
                match (monthMatcher.matches(s[pos..end])) {
                    case Some(data) =>
                        let monthString = data.matchStr(1)
                        month = IndexOfMonthDay(monthString)
                    case None => ()
                }
            } else if (year == -1 && ifMatchYear) {
                match (yearMatcher.matches(s[pos..end])) {
                    case Some(data) => year = Int64.parse(data.matchStr(1))
                    case None => ()
                }
            }
            pos = dateCharacterOffset(s, end + 1, limit, false)
        }
        return checkTime(year, month, dayOfMonth, hour, minute, second)
    }

    private static func matchTime(input: String): Bool {
        let timeMatcher = Regex(TIME_PATTERN)

        match (timeMatcher.matches(input)) {
            case Some(_) => return true
            case None => return false
        }
    }

    private static func matchYear(input: String): Bool {
        let yearMatcher = Regex(YEAR_PATTERN)

        match (yearMatcher.matches(input)) {
            case Some(_) => return true
            case None => return false
        }
    }

    private static func matchDOM(input: String): Bool {
        let domMatcher = Regex(DAY_OF_MONTH_PATTERN)
        return has(domMatcher.matches(input))
    }

    private static func matchMonth(input: String): Bool {
        let monthMatcher = Regex(MONTH_PATTERN)

        match (monthMatcher.matches(input)) {
            case Some(_) => return true
            case None => return false
        }
    }

    private static func checkTime(
        y: Int64,
        month: Int64,
        dayOfMonth: Int64,
        hour: Int64,
        minute: Int64,
        second: Int64
    ): DateTime {
        var year = y

        // Convert two-digit years into four-digit years. 99 becomes 1999, 15 becomes 2015.
        if (year >= 70 && year <= 99) {
            year += 1900
        }

        if (year >= 0 && year <= 69) {
            year += 2000
        }

        // If any partial is omitted or out of range, return -1. The date is impossible. Note that leap
        // seconds are not supported by this syntax.
        if (year < 1601) {
            throw IllegalArgumentException()
        }

        if (month == -1) {
            throw IllegalArgumentException()
        }

        if (dayOfMonth < 1 || dayOfMonth > 31) {
            throw IllegalArgumentException()
        }

        if (hour < 0 || hour > 23) {
            throw IllegalArgumentException()
        }

        if (minute < 0 || minute > 59) {
            throw IllegalArgumentException()
        }

        if (second < 0 || second > 59) {
            throw IllegalArgumentException()
        }

        let time: DateTime = DateTime.of(
            year: year,
            month: Month.of(month),
            dayOfMonth: dayOfMonth,
            hour: hour,
            minute: minute,
            second: second,
            timeZone: TimeZone.load("UTC")
        )

        return time
    }

    private static func getTime(time: Int64): DateTime {
        let standardTime = DateTime.of(year: 1970, month: Month.of(1), dayOfMonth: 1, timeZone: TimeZone.load("UTC"))
        return standardTime + Duration.millisecond * time
    }

    private static func IndexOfMonthDay(s: String): Int64 {
        match (s.toLower()) {
            case "jan" => return 1
            case "feb" => return 2
            case "mar" => return 3
            case "apr" => return 4
            case "may" => return 5
            case "jun" => return 6
            case "jul" => return 7
            case "aug" => return 8
            case "sep" => return 9
            case "oct" => return 10
            case "nov" => return 11
            case "dec" => return 12
            case _ => return -1
        }
    }

    private static func dateCharacterOffset(input: String, pos: Int64, limit: Int64, invert: Bool) {
        for (i in pos..limit) {
            let c = input[i]
            let dateCharacter: Bool = (c < b' ' && c != b'\t') || (c >= b'\u{7f}') || (c >= b'0' && c <= b'9') || (c >= b'a' &&
                c <= b'z') || (c >= b'A' && c <= b'Z') || (c == b':')
            if (dateCharacter == !invert) {
                return i
            }
        }

        return limit
    }

    private static func parseMaxAge(s: String): Int64 {
        try {
            let parsed = Int64.parse(s)
            if (parsed < 0) {
                return Int64.Max
            } else {
                return parsed
            }
        } catch (e: Exception) {
            match (Regex("-?\\d+").matches(s)) {
                case Some(_) => if (s.startsWith("-")) {
                    return Int64.Min
                } else {
                    return Int64.Max
                }
                case None => throw e
            }
        }
    }

    static func parseIPv4(address: String): (Array<UInt8>, Bool) {
        var it = address.lazySplit(".")
        var ip = Array<UInt8>(SOCK_ADDR_IPV4_LEN, item: 0)

        for (i in 0..SOCK_ADDR_IPV4_LEN) {
            match (it.next()) {
                case Some(v) =>
                    if (v.size == 0) {
                        return (Array<UInt8>(), true)
                    }
                    var n = stoi(v)
                    if (n < 0 || n > 255) {
                        return (Array<UInt8>(), true)
                    }
                    ip[i] = UInt8(n)
                case None => return (Array<UInt8>(), true)
            }
        }

        match (it.next()) {
            case None => return (ip, false)
            case _ => return (Array<UInt8>(), true)
        }
    }

    static func parseIPv6Zone(address: String): (Array<UInt8>, String, Bool) {
        var idx = match (address.lastIndexOf("%")) {
            case Some(v) => v
            case None => -1
        }

        var zone = ""
        var ipAddr = address

        if (idx != -1) {
            zone = address.substring(idx + 1)
            ipAddr = address.substring(0, idx)
        }

        var (arr, err) = parseIPv6(ipAddr)
        if (err) {
            return (Array<UInt8>(), "", true)
        }

        return (arr, zone, false)
    }

    @OverflowWrapping
    static func parseIPv6(str: String): (Array<UInt8>, Bool) {
        var s = str
        var ip = Array<UInt8>(SOCK_ADDR_IPV6_LEN, item: 0)
        var ellipsis = -1
        let pk = Array<UInt8>()

        if (s.size >= 2 && s.startsWith("::")) {
            ellipsis = 0
            s = s.trimLeft("::")
            if (s.size == 0) {
                return (ip, true)
            }
        }

        var i = 0
        while (i < SOCK_ADDR_IPV6_LEN) {
            let (n, c, ok) = xtoi(s)
            if (!ok || n > 0xFFFF) {
                return (pk, true)
            }

            if (c < s.size && s[c] == b'.') {
                if (ellipsis < 0 && i != (SOCK_ADDR_IPV6_LEN - SOCK_ADDR_IPV4_LEN)) {
                    return (pk, true)
                }
                if ((i + SOCK_ADDR_IPV4_LEN) > SOCK_ADDR_IPV6_LEN) {
                    return (pk, true)
                }
                var (ip4, ip4b) = parseIPv4(s)
                if (ip4.isEmpty() || ip4b) {
                    return (pk, true)
                }
                ip[i] = ip4[0]
                ip[i + 1] = ip4[1]
                ip[i + 2] = ip4[2]
                ip[i + 3] = ip4[3]
                s = ""
                i += SOCK_ADDR_IPV4_LEN
                break
            }
            ip[i] = UInt8(n >> 8)
            ip[i + 1] = UInt8(n)
            i += 2
            s = s.substring(c)
            if (s.size == 0) {
                break
            }
            if (s[0] != b':' || s.size == 1) {
                return (pk, true)
            }
            s = s.substring(1)
            if (s[0] == b':') {
                if (ellipsis >= 0) {
                    return (pk, true)
                }
                ellipsis = i
                s = s.substring(1)
                if (s.size == 0) {
                    break
                }
            }
        }
        if (s.size != 0) {
            return (pk, true)
        }
        if (i < SOCK_ADDR_IPV6_LEN) {
            if (ellipsis < 0) {
                return (pk, true)
            }
            var n = SOCK_ADDR_IPV6_LEN - i
            for (j in (i - 1)..=ellipsis : -1) {
                ip[j + n] = ip[j]
            }
            for (j in (ellipsis + n - 1)..=ellipsis : -1) {
                ip[j] = 0
            }
        } else if (ellipsis >= 0) {
            return (pk, true)
        }
        return (ip, false)
    }

    static func xtoi(s: String): (Int64, Int64, Bool) {
        var n = 0
        var m = 0
        var i = 0
        for (c in s.toRuneArray()) {
            m = i + 1
            if (r'0' <= c && c <= r'9') {
                n *= 16
                n += Int64(UInt32(c)) - Int64(b'0')
            } else if (r'a' <= c && c <= r'f') {
                n *= 16
                n += Int64(UInt32(c)) - Int64(b'a') + 10
            } else if (r'A' <= c && c <= r'F') {
                n *= 16
                n += Int64(UInt32(c)) - Int64(b'A') + 10
            } else {
                m = i
                break
            }
            if (n >= BIG) {
                return (0, i, false)
            }
            i++
        }

        if (m == 0) {
            return (0, m, false)
        }

        return (n, m, true)
    }

    static func stoi(s: String): Int64 {
        var num: Int64 = 0
        for (u in s) {
            if (u < b'0' || u > b'9') {
                return -1
            }
            var n = u - b'0'
            num = num * 10 + Int64(n)
        }

        return num
    }
}

func getTimeStamp(time: DateTime): Int64 {
    let standardTime = DateTime.of(year: 1970, month: Month.of(1), dayOfMonth: 1, timeZone: TimeZone.load("UTC"))
    return (time - standardTime).toMilliseconds()
}
