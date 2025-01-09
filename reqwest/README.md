## 介绍

Request 是一个基于Httpclient4cj(OkHttp)的高效率 ArkTs HTTP 客户端

## 特性

- 支持HTTP/2，允许所有同一个主机地址的请求共享同一个 socket 连接
- 连接池减少请求延时
- 缓存响应内容，避免一些完全重复的请求
- 简洁的链式调用API
- 支持多种responseBody转换策略
- 仓颉协程spawn支持

## 下载/安装

ohpm install @axzo/ok-request

## 示例

### 初始配置

开启网络请求权限
module.json5
```json5
"requestPermissions": [
{
"name": "ohos.permission.INTERNET"
}
],
```
创建配置config
```typescript

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
```

创建client

```typescript
let client = new OkHttpClient(config)
```

### GET请求示例

```typescript
let res: ResponseBody = await this.client.get('https://baidu.com').send()
```

### POST请求示例

json body
```typescript
let res: ResponseBody = await this.client.post('xx/xx/xx').json({
  s: '1',
  a: 2
}).send()
```

### HEADER 设置

```typescript
let res: ResponseBody = await this.client.post('xx/xx/xx').json({
  s: '1',
  a: 2
}).head('name', 'value').head('xxx', 'xxxx').send()
```

### BODY解析示例

TEXT 解析
```typescript
res?.text()
```

JSON 解析
```typescript
res?.json<T>()
```

ArrayBuffer
```typescript
res?.bytes()
```

### 取消请求

取消当前client所有请求
```typescript
this.client.cancelAll()
```

根据requestId取消请求
```typescript
let request = this.client.get('https://baidu.com').build()
await this.client.execute(request)
this.client.cancel(request)
```

### 上传单个文件

```typescript
let result = await this.client.post('xxx.xxx.xxx').file(new FileBody(path, contentType)).send()
```

### 上传多个文件 Multipart
```typescript
let multipart = new MultiPartBodyBuilder()
  .addFormDataPart('file', 'filename.txt', new FileBody(path, "text/plain"))
  .addTextFormDataPart('key', 'dsa')
  .build()
let result = await this.client.post('xxx.xxx.xxx').multipart(multipart).send()
```

### 异常处理

```typescript
try {
  await this.client.get('https://baidu.com').send()
} catch(e: HttpError) {

}
```