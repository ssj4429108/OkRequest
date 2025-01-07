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