/**
 * Created on 2025/3/26
 */
package ohos_app_cangjie_OkRequest
import ohos_app_cangjie_OkRequest.okhttp.*
import std.time.*
import encoding.url.*
main() {
    let url = URL.parse("https://www.baidu.com")
    let client: HttpClient = HttpClient.builder()
        .connectTimeout(Duration.second)
        .readTimeout(Duration.second)
        .writeTimeout(Duration.second)
        .build()
    let request = Request.builder().url(url).build()
    let call = client.newCall(request)
    let response = call.execute()
    println(response.getBody().getOrThrow().getString())
}