## 版本更新记录


### 1.0.0 / 2025-1-6

- 基于httpclient4cj（okhttp）实现ArkTs的API层暴露
- 完成基础GET,PUT,POST等请求支持
- 支持form，query，json等的Content-Type

### 1.0.1 / 2025-1-7

- 新增文件上传
- 支持multipart
- 新增RequestBody interface
- 新增RequestBuilder.file()
- 新增RequestBuilder.multipart()
- 新增MultipartBodyBuilder及FileBody

### 1.0.2 / 2025-1-8

- 新增TextRequestBody
- 异步化createRealRequest，调整request body to bytes 至 promise
- 统一request body转化逻辑

### 1.0.3 / 2025-1-8
- ResponseBody 新增 text， json 及 bytes function
- 更改 RequestBuild.json<T>(data: any) to RequestBuild.json<T>(data: Record<string, any> | any)

### 1.0.4 / 2025-1-9
- 新增tlsConfig支持自签名
- 更改OkConfig class -> interface

### 1.0.5 / 2025-1-13
- 新增dns解析API

### 1.0.6 / 2025-2-28
- HttpError新增request， name及message

### 1.0.7 / 2025-3-10
- Response新增headers

### 1.0.8 / 2025-3-11
- 修复 headers 跟arkts交互异常问题

### 1.0.9 / 2025-3-11
- 修复1.0.8构建缓存问题

### 1.0.10 / 2025-3-11
- 新增cacheControl

### 1.0.11 / 2025-3-12
- 设置cacheControl api移至requestBuilder

### 1.0.12 / 2025-3-13
- cacheControl 默认值-1异常问题修复

### 1.0.13 / 2025-3-13
- 新增RequestBuilder

### 1.0.14 / 2025-3-17
- 修复文件上传content-type错误的问题

### 1.0.15 / 2025-3-28
- 底层使用rust reqwest 替换httpclient4cj

### 1.0.16 / 2025-4-1
- 新增abortController

### 1.0.17 / 2025-4-1
- 修复request body 跟 rust侧交互异常的问题

### 1.0.18 / 2025-4-1
- 修复response header不包含content-length导致异常的问题

### 1.0.19 / 2025-4-1
- 暴露RequestBuilder

### 1.0.20 / 2025-4-2
- 新增Request.toCurl
- HttpClient Config 新增enableCurlLog 开关
- request 新增 cacheOption 配置

### 1.0.21 / 2025-4-8
- ResponseBody json 方法新增cls类型可选参数

### 1.0.22 / 2025-7-22
- 修复ByteArrayStream全量读取position未重置的问题
- 新增忽略ssl校验配置到tlsConfig

### 1.0.23 / 2025-10-29
- 新增SSE模式

### 1.0.24 / 2025-11-4
- 对SSE新增abort操作
- 优化ohos_reqwest api
- 统一send调用风格