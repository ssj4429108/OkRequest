import { OkConfig, OkHttpClient, Request, CacheMode, MultipartBodyBuilder, FileBody } from '@axzo/ok-request';
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
          const result = await this.client.get(
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