import { OkConfig, OkHttpClient, Request, VerifyMode } from '@axzo/ok-request';

const config: OkConfig = {
  requestInterceptors: [],
  responseInterceptors: [],
  timeout: 30,
  maxConnections: 5,
  baseUrl: undefined,
  protocols: undefined,
  tlsConfig: undefined
}

config.requestInterceptors.push({
  intercept: (request: Request) => {
    return request.newBuilder()
      .head('1', '2')
      .build()
  }
})

config.tlsConfig = {
  verifyMode: VerifyMode.ALL,
  pem: undefined
}

@Entry
@Component
struct Index {
  @State message: string = 'Hello World';
  client = new OkHttpClient(config)

  build() {
    RelativeContainer() {
      Text(this.message)
        .fontSize(40)
        .fontWeight(FontWeight.Bold)
        .alignRules({
          center: { anchor: '__container__', align: VerticalAlign.Center },
          middle: { anchor: '__container__', align: HorizontalAlign.Center }
        })
        .onClick(async () => {
          try {
            let res = await this.client.get("http://baidu.com").send()
            console.log(res?.text())
          } catch (e) {
            console.log(e)
          }
        })
    }
    .height('100%')
    .width('100%')
  }
}