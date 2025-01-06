/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2022-2024. All rights resvered.
 */

/**
 * @file
 * The file declares the FormBody class.
 */

package ohos_app_cangjie_reqwest.okhttp

/**
 * The class is FormBody
 * @author luoyukai4
 * @since 0.33.3
 */
public class FormBody <: RequestBody {
    private static let CONTENT_TYPE: MediaType = MediaType.get("application/x-www-form-urlencoded")
    private let form: Form

    init(form: Form) {
        this.form = form
    }

    public func contentType(): Option<MediaType> {
        return CONTENT_TYPE
    }

    public func getContentLength(): Int64 {
        return form.toEncodeString().size
    }

    public func writeTo(sink: Sink): Unit {
        sink.write(form.toEncodeString().toUtf8Array())
    }

    public static func builder(): FormBodyBuilder {
        return FormBodyBuilder()
    }

    public func get(): InputStream {
        let arr = ByteArrayStream()
        arr.write(form.toEncodeString().toUtf8Array())
        return arr
    }
}

public class FormBodyBuilder <: Builder<FormBody> {
    private let form: Form = Form()

    init() {}

    public func build(): FormBody {
        return FormBody(form)
    }

    public func add(name: String, value: String): FormBodyBuilder {
        form.add(name, value)
        return this
    }
}
