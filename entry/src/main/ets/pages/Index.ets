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

          const encodedQuestion = encodeURIComponent("建筑工程?") //系统阴阳角保温结构
          const api =
            `https://test-api.axzo.cn/ai-assistant/webApi/ai/assistant/bot/chatStream?question=${encodedQuestion}&showReason=${false}`

          // 使用自定义的 AbortController
           this.client.get(api)
            .head({
              "Authorization": "Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJsb2dpblR5cGUiOiJsb2dpbiIsImxvZ2luSWQiOiJOVF9BUFBfR0VORVJBTDo3NDI5OSIsInJuU3RyIjoiVjlIeHhOMVpkRkNFTlBZU3lXYU04SXk3MTR4Wko2c1AifQ.Ow8qUgvwKd6PKUteD-UeDKvCTl8ycG6AcmsqoNOWEx0"
            })
            .signal(this.controller)
            .toEventSource({
              onMessage(event: string) {
                console.log(event)
              },
              onError(error: string) {
                console.log(error)
              }
            })
            .send()

          // await request.send()
          // // 执行 SSE 连接
          // await request.sse(
          //   (msg: string) => {
          //     console.info('收到 SSE 消息:', msg);
          //   },
          //   (err: Error) => {
          //     // 区分是用户主动取消还是其他错误
          //     if (err.message === 'request aborted by signal.') {
          //       console.info('请求已被用户取消');
          //     } else {
          //       console.error('SSE 错误:', err);
          //     }
          //   }
          // );
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