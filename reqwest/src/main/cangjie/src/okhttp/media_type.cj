/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2022-2024. All rights resvered.
 */

/**
 * @file
 * The file declares the all interfaces.
 */

package ohos_app_cangjie_reqwest.okhttp

public class MediaType <: ToString {
    private static let TOKEN: String = "([a-zA-Z0-9-!#$%&'*+.^_`{|}~]+)"
    private static let QUOTED: String = "\"([^\"]*)\""

    private let string: String
    private let mediaType: String
    private let subtype: String
    private let charset: String

    private init(string: String, mediaType: String, subtype: String, charset: String) {
        this.string = string
        this.mediaType = mediaType
        this.subtype = subtype
        this.charset = charset
    }

    public static func get(string: String): MediaType {
        let typeSubtype: Matcher = Regex("^" + TOKEN + "/" + TOKEN).matcher(string)
        var mediaType: String = ""
        var subtype: String = ""
        var end = 0
        match (typeSubtype.find()) {
            case None => throw IllegalArgumentException("No subtype found for: \"${string}\"")
            case Some(data) =>
                mediaType = data.matchStr(1).toLower()
                subtype = data.matchStr(2).toLower()
                end = data.matchPosition(2).end
        }

        let parameter: Matcher = Regex(";\\s*(?:" + TOKEN + "=(?:" + TOKEN + "|" + QUOTED + "))?").matcher(string)
        var charset = ""
        var s = end
        for (_ in end..string.size) {
            if (s == string.size) {
                break
            }
            parameter.setRegion(s, string.size)
            match (parameter.find()) {
                case None => throw IllegalArgumentException(
                    "Parameter is not formatted correctly: \"${string.substring(s)}\" for: \"${string}\"")
                case Some(data) =>
                    s = data.matchPosition(0).end
                    let name = data.matchStr(1).toLower()
                    if (name == "" || !equalsIgnoreCase(name, "charset")) {
                        continue
                    }
                    var charsetParameter: String
                    let token = data.matchStr(2).toLower()

                    if (token != "") {
                        if (token.startsWith("'") && token.endsWith("'") && token.size > 2) {
                            charsetParameter = token.substring(1, token.size - 2)
                        } else {
                            charsetParameter = token
                        }
                    } else {
                        charsetParameter = data.matchStr(3)
                    }

                    if (charset != "" && !equalsIgnoreCase(charsetParameter, charset)) {
                        throw IllegalArgumentException(
                            "Multiple charsets defined: \"${charset}\" and: \"${charsetParameter}\" for: \"${string}\"")
                    }

                    charset = charsetParameter
            }
        }
        return MediaType(string, mediaType, subtype, charset)
    }

    public static func parse(string: String): Option<MediaType> {
        try {
            return get(string)
        } catch (e: Exception) {
            return Option<MediaType>.None
        }
    }

    public func getType(): String {
        return mediaType
    }
    public func getSubtype(): String {
        return subtype
    }

    public func getCharset(): String {
        return charset
    }

    public func toString() {
        return string
    }
}
