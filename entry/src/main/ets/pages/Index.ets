import { OkConfig, OkHttpClient, Request, VerifyMode, Response, RequestBodyBuilder, HttpError } from '@axzo/ok-request';
import { image } from '@kit.ImageKit';
import { common } from '@kit.AbilityKit';
import { LivenessDetection } from '../utils/Index'
import { url, util, xml } from '@kit.ArkTS';
import { FileUploadResp } from '../pojo';
import utils from '@arkts.utils';

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

}

class AxzHttpResponse<T> {
  code: number = 0
  message?: string = ""
  data?: T | undefined
}


// config.requestInterceptors.push({
//   intercept: (request: Request) => {
//     return request.newBuilder()
//       .head('1', '2')
//       .build()
//   }
// })
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
          let resp = await this.client.get('http://www.baidu.com').send()
          console.log(resp?.text())
        })
      Text('测试')
        .fontSize(40)
        .fontWeight(FontWeight.Bold)
        .onClick(() => {
          try {
            let resp = this.client.get('https://www.baidu.com').sendSync()
            console.log(resp?.text())
          } catch (e) {

          }
        })
    }
    .height('100%')
    .width('100%')
  }

  onPageShow(): void {

  }

}