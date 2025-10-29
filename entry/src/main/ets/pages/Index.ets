import { OkConfig, OkHttpClient, Request, CacheMode, MultipartBodyBuilder, FileBody } from '@axzo/ok-request';
import fileIo from '@ohos.file.fs';
import { util } from '@kit.ArkTS';

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


@Entry
@Component
struct Index {
  @State message: string = 'Hello World';
  client = new OkHttpClient(config)
  private isLivenessDetection: boolean = false

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
          // let resp = await this.client.get('http://www.baidu.com').send()
          // await this.client.get("112321").send()

          // 简单用法
          await this.client.get('https://api.example.com/events')
            .sse(
              (msg: string) => {
                console.info('收到 SSE 消息:', msg);
              },
              (err: Error) => {
                console.error('SSE 错误:', err);
              }
            );

        })
    }
    .height('100%')
    .width('100%')
  }

  onPageShow(): void {

  }
}