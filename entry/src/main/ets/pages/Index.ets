import { OkConfig, OkHttpClient, Request } from '@axzo/ok-request';

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

        })
    }
    .height('100%')
    .width('100%')
  }
}