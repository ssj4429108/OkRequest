/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2022-2024. All rights resvered.
 */

/**
 * @file
 * The file declares the Protocol enum.
 */

package ohos_app_cangjie_OkRequest.okhttp

public enum Protocol <: ToString {
    /**
     * An obsolete plaintext framing that does not use persistent sockets by default.
     */
    HTTP_1_0 | HTTP_1_1 | HTTP_2 | H2_PRIOR_KNOWLEDGE

    /**
     * The Function is get
     *
     * @param protocol of String
     *
     * @return Type of Protocol
     * @since 0.29.3
     */
    public static func get(protocol: String): Protocol {
        return match (protocol) {
            case "http/1.0" | "HTTP/1.0" => HTTP_1_0
            case "http/1.1" | "HTTP/1.1" => HTTP_1_1
            case "h2" | "H2" | "http/2.0" | "HTTP/2.0" => HTTP_2
            case "h2_prior_knowledge" | "H2_PRIOR_KNOWLEDGE" => H2_PRIOR_KNOWLEDGE
            case _ => throw ProtocolException("no find protocol")
        }
    }

    /**
     * The Function is toString
     *
     * @return Type of String
     * @since 0.29.3
     */
    public func toString(): String {
        match (this) {
            case HTTP_1_0 => "http/1.0"
            case HTTP_1_1 => "http/1.1"
            case HTTP_2 => "h2"
            case H2_PRIOR_KNOWLEDGE => "h2_prior_knowledge"
        }
    }
}
