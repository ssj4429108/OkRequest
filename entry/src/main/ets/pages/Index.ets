import { OkConfig, OkHttpClient } from '@axzo/ok-request';

const config = new OkConfig(
  5,
  30
)

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
            let res = await this.client.get('https://baidu.com').send()
            console.log(res?.text() || "哈哈")
          } catch (e) {
            console.log(e)
          }
        })
    }
    .height('100%')
    .width('100%')
  }
}