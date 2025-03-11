import { OkConfig, OkHttpClient, Request, VerifyMode, Response } from '@axzo/ok-request';
import { socket } from '@kit.NetworkKit';

const config: OkConfig = {
  requestInterceptors: [],
  responseInterceptors: [],
  timeout: 30,
  maxConnections: 5,
  baseUrl: undefined,
  protocols: undefined,
  tlsConfig: {
    verifyMode: VerifyMode.ALL,
    pem: undefined
  },
  dns: undefined,
  cacheControl: {

  }
}

config.requestInterceptors.push({
  intercept: (request: Request) => {
    return request.newBuilder()
      .head('1', '2')
      .build()
  }
})

config.responseInterceptors.push({
  intercept: (response: Response | undefined) => {
    return response
  }
})


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
            // let res = await this.client.get("http://baidu.com").dns([{address: '192.168.1.1', family: 1}]).send()
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