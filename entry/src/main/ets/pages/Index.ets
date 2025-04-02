import { OkConfig, OkHttpClient, Request, CacheMode } from '@axzo/ok-request';
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
          // let resp = await this.client.get('http://www.baidu.com').send()
          try {
            let resp = await this.client.post('http://test-api.axzo.cn/yoke/webApi/oss/signUrl/fetchUploadWhite').json({
              bizScene: 'avatar',
              appCode: "avatar",
              fileName: '4ed8874f11bb4535918009c3268b2300.jpeg'
            }).cacheControl({
              cacheMode: CacheMode.Default
            }).send()
            console.log(resp?.text())
          } catch (e) {
            console.error(e)
          }
        })
      Text('测试')
        .fontSize(40)
        .fontWeight(FontWeight.Bold)
        .onClick(async () => {
          let resp = await this.client.get('http://www.baidu.com').send()
          console.log(resp?.text())
          // try {
          //   let resp = this.client.get('https://www.baidu.com').sendSync()
          //   console.log(resp?.text())
          // } catch (e) {
          //   console.error(e)
          // }
        })
    }
    .height('100%')
    .width('100%')
  }

  onPageShow(): void {

  }

}