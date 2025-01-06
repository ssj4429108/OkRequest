/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2022-2024. All rights resvered.
 */

package ohos_app_cangjie_reqwest.okhttp

/**
 * @file The file manage errorCode.
 */

/**
 * The enum is ErrorCode of http2
 * @author luoyukai4
 * @since 0.34.3
 */
public enum ErrorCode {
    | NO_ERROR
    | PROTOCOL_ERROR
    | INTERNAL_ERROR
    | FLOW_CONTROL_ERROR
    | REFUSED_STREAM
    | CANCEL
    | COMPRESSION_ERROR
    | CONNECT_ERROR
    | ENHANCE_YOUR_CALM
    | INADEQUATE_SECURITY
    | HTTP_1_1_REQUIRED

    /**
     * The Function is fromHttp2
     *
     * @param errorCodeInt of Int64
     *
     * @return Type of Option<ErrorCode>
     * @since 0.34.3
     */
    public static func fromHttp2(errorCodeInt: Int64): Option<ErrorCode> {
        match (errorCodeInt) {
            case 0 => return NO_ERROR
            case 1 => return PROTOCOL_ERROR
            case 2 => return INTERNAL_ERROR
            case 3 => return FLOW_CONTROL_ERROR
            case 7 => return REFUSED_STREAM
            case 8 => return CANCEL
            case 9 => return COMPRESSION_ERROR
            case 0xa => return CONNECT_ERROR
            case 0xb => return ENHANCE_YOUR_CALM
            case 0xc => return INADEQUATE_SECURITY
            case 0xd => return HTTP_1_1_REQUIRED
            case _ => return Option<ErrorCode>.None
        }
    }

    /**
     * The Function is getCode
     *
     * @return Type of Int64
     * @since 0.34.3
     */
    public func getCode(): Int64 {
        match (this) {
            case NO_ERROR => return 0
            case PROTOCOL_ERROR => return 1
            case INTERNAL_ERROR => return 2
            case FLOW_CONTROL_ERROR => return 3
            case REFUSED_STREAM => return 7
            case CANCEL => return 8
            case COMPRESSION_ERROR => return 9
            case CONNECT_ERROR => return 0xa
            case ENHANCE_YOUR_CALM => return 0xb
            case INADEQUATE_SECURITY => return 0xc
            case HTTP_1_1_REQUIRED => return 0xd
        }
    }

    /**
     * The Function is toString
     *
     * @since 0.34.3
     */
    public func toString() {
        match (this) {
            case NO_ERROR => return "NO_ERROR"
            case PROTOCOL_ERROR => return "PROTOCOL_ERROR"
            case INTERNAL_ERROR => return "INTERNAL_ERROR"
            case FLOW_CONTROL_ERROR => return "FLOW_CONTROL_ERROR"
            case REFUSED_STREAM => return "REFUSED_STREAM"
            case CANCEL => return "CANCEL"
            case COMPRESSION_ERROR => return "COMPRESSION_ERROR"
            case CONNECT_ERROR => return "CONNECT_ERROR"
            case ENHANCE_YOUR_CALM => return "ENHANCE_YOUR_CALM"
            case INADEQUATE_SECURITY => return "INADEQUATE_SECURITY"
            case HTTP_1_1_REQUIRED => return "HTTP_1_1_REQUIRED"
        }
    }
}
