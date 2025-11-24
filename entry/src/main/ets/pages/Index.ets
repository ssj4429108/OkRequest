import { OkConfig, OkHttpClient, Request, CacheMode, MultipartBodyBuilder, FileBody,
  RequestBodyBuilder,
  TextRequestBody} from '@axzo/ok-request';
import fileIo from '@ohos.file.fs';
import { util } from '@kit.ArkTS';
import { AbortController } from '@ohos-rs/abort-controller';

// import { toCurl, CacheMode } from '@axzo/ok-request/src/main/cpp/types/libohos_reqwest';

const config: OkConfig = {
  requestInterceptors: [],
  responseInterceptors: [],
  timeout: 30,
  maxConnections: 5,
  baseUrl: undefined,
  protocols: undefined,
  tlsConfig: undefined,
  enableCurlLog: true
}


config.requestInterceptors.push({
  intercept: (request: Request) => {
    console.log(request.toCurl())
    return request
  }
})

//
// config.responseInterceptors.push({
//   intercept: (response: Response | undefined) => {
//     return response
//   }
// })
// 定义 AbortSignal 接口
// 定义 AbortSignal 接口


@Entry
@Component
struct Index {
  @State message: string = 'Hello World';
  client = new OkHttpClient(config)
  private isLivenessDetection: boolean = false
  private controller = new AbortController();

  private string2BytesSync(data: string): ArrayBuffer {
    let encoder = util.TextEncoder.create('utf-8')
    let uint8Array = encoder.encodeInto(data)
    return uint8Array
  }
  build() {
    Column() {
      Text(this.message)
        .fontSize(40)
        .fontWeight(FontWeight.Bold)
        .onClick(async () => {
        })
      Text('测试')
        .fontSize(40)
        .fontWeight(FontWeight.Bold)
        .onClick(async () => {
          const result = await this.client.put(
            "https://www.baidu.com/"
          ).send()
        })

      // 添加取消按钮
      Button('取消请求')
        .onClick(() => {
          this.controller.abort()
        })
    }
    .height('100%')
    .width('100%')
  }

  onPageShow(): void {

  }
}