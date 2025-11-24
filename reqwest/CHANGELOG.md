## 版本更新记录

### 1.0.0 / 2025-1-6

-   基于 httpclient4cj（okhttp）实现 ArkTs 的 API 层暴露
-   完成基础 GET,PUT,POST 等请求支持
-   支持 form，query，json 等的 Content-Type

### 1.0.1 / 2025-1-7

-   新增文件上传
-   支持 multipart
-   新增 RequestBody interface
-   新增 RequestBuilder.file()
-   新增 RequestBuilder.multipart()
-   新增 MultipartBodyBuilder 及 FileBody

### 1.0.2 / 2025-1-8

-   新增 TextRequestBody
-   异步化 createRealRequest，调整 request body to bytes 至 promise
-   统一 request body 转化逻辑

### 1.0.3 / 2025-1-8

-   ResponseBody 新增 text， json 及 bytes function
-   更改 RequestBuild.json<T>(data: any) to RequestBuild.json<T>(data: Record<string, any> | any)

### 1.0.4 / 2025-1-9

-   新增 tlsConfig 支持自签名
-   更改 OkConfig class -> interface

### 1.0.5 / 2025-1-13

-   新增 dns 解析 API

### 1.0.6 / 2025-2-28

-   HttpError 新增 request， name 及 message

### 1.0.7 / 2025-3-10

-   Response 新增 headers

### 1.0.8 / 2025-3-11

-   修复 headers 跟 arkts 交互异常问题

### 1.0.9 / 2025-3-11

-   修复 1.0.8 构建缓存问题

### 1.0.10 / 2025-3-11

-   新增 cacheControl

### 1.0.11 / 2025-3-12

-   设置 cacheControl api 移至 requestBuilder

### 1.0.12 / 2025-3-13

-   cacheControl 默认值-1 异常问题修复

### 1.0.13 / 2025-3-13

-   新增 RequestBuilder

### 1.0.14 / 2025-3-17

-   修复文件上传 content-type 错误的问题

### 1.0.15 / 2025-3-28

-   底层使用 rust reqwest 替换 httpclient4cj

### 1.0.16 / 2025-4-1

-   新增 abortController

### 1.0.17 / 2025-4-1

-   修复 request body 跟 rust 侧交互异常的问题

### 1.0.18 / 2025-4-1

-   修复 response header 不包含 content-length 导致异常的问题

### 1.0.19 / 2025-4-1

-   暴露 RequestBuilder

### 1.0.20 / 2025-4-2

-   新增 Request.toCurl
-   HttpClient Config 新增 enableCurlLog 开关
-   request 新增 cacheOption 配置

### 1.0.21 / 2025-4-8

-   ResponseBody json 方法新增 cls 类型可选参数

### 1.0.22 / 2025-7-22

-   修复 ByteArrayStream 全量读取 position 未重置的问题
-   新增忽略 ssl 校验配置到 tlsConfig

### 1.0.23 / 2025-10-29

-   新增 SSE 模式

### 1.0.24 / 2025-11-4

-   对 SSE 新增 abort 操作
-   优化 ohos_reqwest api
-   统一 send 调用风格

### 1.0.25 / 2025-11-4

-   更改 abort 异常抛出方式

### 1.0.26 / 2025-11-24

-   修复大文件上传异常问题
