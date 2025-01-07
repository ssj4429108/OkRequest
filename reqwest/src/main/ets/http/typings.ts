import { ArkResponse, ArkResponseBody, ArkHeader } from "ok_reqwest_api.so"
import util from '@ohos.util';
import { OkHttpClient } from ".";
import { JSON } from "@kit.ArkTS";
import { fileIo as fs, ReadOptions } from '@kit.CoreFileKit';


interface RequestInterceptor {
  intercept(request: Request): Request
}

interface ResponseInterceptor {
  intercept(response: Response | undefined): Response | undefined
}


export class OkConfig {
  readonly requestInterceptors: RequestInterceptor[] = []
  readonly responseInterceptors: ResponseInterceptor[] = []
  readonly timeout: number
  readonly maxConnections: number
  baseUrl: string | undefined

  constructor(timeout: number = 30, maxConnections: number = 5) {
    this.timeout = timeout
    this.maxConnections = maxConnections
  }

  setBaseUrl(baseUrl: string) {
    this.baseUrl = baseUrl
  }

  addRequestInterceptor(interceptor: (request: Request) => Request) {
    function createInterceptor(): RequestInterceptor {
      return {
        intercept(request: Request): Request {
          return interceptor.call(this, request)
        }
      }
    }
    this.requestInterceptors.push(createInterceptor())
  }

  addResponseInterceptor(interceptor: (response: Response) => Response) {
    function createInterceptor(): ResponseInterceptor {
      return {
        intercept(response: Response | undefined): Response | undefined {
          return interceptor.call(this, response)
        }
      }
    }
    this.responseInterceptors.push(createInterceptor())
  }
}

export class Request {
  readonly url: string
  readonly method?: HttpMethod | undefined
  readonly headers: Array<ArkHeader> = []
  readonly mediaType?: string | undefined
  readonly body?: ArrayBuffer | undefined

  private client: OkHttpClient

  readonly requestId: string

  constructor(builder: RequestBuilder) {
    this.url = builder.url
    this.method = builder.method
    this.headers = builder.headers
    this.mediaType = builder.mediaType
    this.body = builder.body
    this.client = builder.client
    this.requestId = util.generateRandomUUID(true)
  }

  newBuilder(): RequestBuilder {
    let builder = new RequestBuilder(this.client)
    builder.url = this.url
    builder.method = this.method
    builder.headers = this.headers
    builder.mediaType = this.mediaType
    builder.body = this.body
    return builder
  }
}

interface RequestBody {
  bytesSync(): ArrayBuffer
  bytes(): Promise<ArrayBuffer>
}

export class Part {
  body: ArrayBuffer
  originalType: string
}

export class MultipartBody implements RequestBody{
  parts: Part[] = []
  bytesSync(): ArrayBuffer {
    throw new Error("Method not implemented.");
  }

  bytes(): Promise<ArrayBuffer> {
    throw new Error("Method not implemented.");
  }
}

export class MultipartBodyBuilder {

}

export class FileBody implements RequestBody{
  readonly originalType: string
  private path: string
  constructor(path: string, originalType: string = 'application/octet-stream') {
    this.path = path
    this.originalType = originalType
  }

  bytesSync(): ArrayBuffer {
    let file = fs.openSync(this.path)
    let bufferSize = fs.statSync(this.path).size
    let buf = new ArrayBuffer(bufferSize)
    let readSize = 0

    let readOptions: ReadOptions = {
      offset: readSize,
      length: bufferSize
    }
    let _ = fs.readSync(file.fd, buf, readOptions)
    fs.closeSync(file)
    return buf
  }

  async bytes(): Promise<ArrayBuffer> {
    let stat = await fs.stat(this.path)
    let bufferSize = stat.size
    let buf = new ArrayBuffer(bufferSize)
    let readSize = 0

    let file = await fs.open(this.path)
    let readOptions: ReadOptions = {
      offset: readSize,
      length: bufferSize
    }
    let _ = await fs.read(file.fd, buf, readOptions)
    await fs.close(file)
    return buf
  }
}

export class RequestBuilder {
  readonly client: OkHttpClient
  url: string
  method?: HttpMethod
  headers: Array<ArkHeader> = []
  body?: ArrayBuffer
  mediaType?: string

  constructor(client: OkHttpClient) {
    this.client = client
  }

  head(name: string, value: string): RequestBuilder {
    this.setHead(name, value)
    return this
  }

  private setHead(name: string, value: string) {
    let filters = this.headers.filter((item) => {
      return item.name == name
    })
    if (filters.length == 0) {
      let header = this.client.createHeader(name, value)
      this.headers.push(header)
    }
  }

  bearerAuth(token: string): RequestBuilder {
    this.setHead('Authorization', `Bearer ${token}`)
    return this
  }

  query(query: Record<string, any>): RequestBuilder {
    let separator = this.url.includes('?') ? '&' : '?'
    let queryEncoded = this.toUrlencoded(query)
    this.url = this.url + separator + queryEncoded
    return this
  }

  form(form: Record<string, any>): RequestBuilder {
    this.setHead('Content-Type', 'application/x-www-form-urlencoded')
    this.mediaType = 'application/x-www-form-urlencoded'
    this.intoBody(this.toUrlencoded(form))
    return this
  }

  json(data: any): RequestBuilder {
    this.setHead('Content-Type', 'application/json; charset=utf-8')
    this.mediaType = 'application/json; charset=utf-8'
    this.intoBody(JSON.stringify(data))
    return this
  }

  bytes(buffer: ArrayBuffer, contentType: string): RequestBuilder {
    this.setHead('Content-Type', contentType)
    this.body = buffer
    return this
  }

  // file(filePath: string, contentType: string = 'application/octet-stream'): RequestBuilder {
  //   this.setHead('Content-Type', contentType)
  //   this.mediaType = contentType
  //   this.fileIntoBody(filePath)
  //   return this
  // }

  private toUrlencoded(obj: Record<string, any>): string {
    return Object.entries(obj)
      .map(([key, value]) => {
        if (Array.isArray(value)) {
          return value.map(item => `${encodeURIComponent(key)}=${encodeURIComponent(String(item))}`).join('&')
        }
        return `${encodeURIComponent(key)}=${encodeURIComponent(String(value))}`
      })
      .join('&')
  }

  private intoBody(data: string) {
    let encoder = util.TextEncoder.create('utf-8')
    let uint8Array = encoder.encodeInto(data)
    this.body = uint8Array.buffer
  }



  build(): Request {
    return new Request(this)
  }

  send(): Promise<Response | undefined> {
    let request = this.build()
    return this.client.execute(request)
  }
}

export enum HttpStatusCode {
  Continue = 100,
  SwitchingProtocols = 101,
  Processing = 102,
  EarlyHints = 103,
  Ok = 200,
  Created = 201,
  Accepted = 202,
  NonAuthoritativeInformation = 203,
  NoContent = 204,
  ResetContent = 205,
  PartialContent = 206,
  MultiStatus = 207,
  AlreadyReported = 208,
  ImUsed = 226,
  MultipleChoices = 300,
  MovedPermanently = 301,
  Found = 302,
  SeeOther = 303,
  NotModified = 304,
  UseProxy = 305,
  Unused = 306,
  TemporaryRedirect = 307,
  PermanentRedirect = 308,
  BadRequest = 400,
  Unauthorized = 401,
  PaymentRequired = 402,
  Forbidden = 403,
  NotFound = 404,
  MethodNotAllowed = 405,
  NotAcceptable = 406,
  ProxyAuthenticationRequired = 407,
  RequestTimeout = 408,
  Conflict = 409,
  Gone = 410,
  LengthRequired = 411,
  PreconditionFailed = 412,
  PayloadTooLarge = 413,
  UriTooLong = 414,
  UnsupportedMediaType = 415,
  RangeNotSatisfiable = 416,
  ExpectationFailed = 417,
  ImATeapot = 418,
  MisdirectedRequest = 421,
  UnprocessableEntity = 422,
  Locked = 423,
  FailedDependency = 424,
  TooEarly = 425,
  UpgradeRequired = 426,
  PreconditionRequired = 428,
  TooManyRequests = 429,
  RequestHeaderFieldsTooLarge = 431,
  UnavailableForLegalReasons = 451,
  InternalServerError = 500,
  NotImplemented = 501,
  BadGateway = 502,
  ServiceUnavailable = 503,
  GatewayTimeout = 504,
  HttpVersionNotSupported = 505,
  VariantAlsoNegotiates = 506,
  InsufficientStorage = 507,
  LoopDetected = 508,
  NotExtended = 510,
  NetworkAuthenticationRequired = 511,
}

export enum HttpMethod {
  GET = 'GET',
  DELETE = 'DELETE',
  HEAD = 'HEAD',
  OPTIONS = 'OPTIONS',
  POST = 'POST',
  PUT = 'PUT',
  PATCH = 'PATCH',
  PURGE = 'PURGE',
  LINK = 'LINK',
  UNLINK = 'UNLINK'
}


export class Response {
  readonly code: HttpStatusCode
  readonly body: ResponseBody | undefined
  readonly message: string

  readonly successfully: boolean

  readonly request: Request

  constructor(response: ArkResponse, request: Request) {
    this.request = request
    this.code = response.code as HttpStatusCode
    let responseBody: ResponseBody | undefined
    if (response.body) {
      responseBody = new ResponseBody(response.body)
    }
    this.body = responseBody
    this.message = response.message
    this.successfully = response.isSuccess
  }

  private bodyAvailable() {
    if (!this.body) {
      return false
    }
    let bin = this.body.data
    if (!bin) {
      return false
    }
    return true
  }

  text(): string | undefined {
    if (!this.bodyAvailable()) {
      return undefined
    }
    let bytes = this.body?.data!
    let decoder = util.TextDecoder.create('utf-8', { ignoreBOM: true })
    return decoder.decodeToString(new Uint8Array(bytes))
  }

  json<T>(): T | undefined {
    if (!this.bodyAvailable()) {
      return undefined
    }
    let text = this.text()
    if (!text) {
      return undefined
    }
    return JSON.parse(text) as T
  }

  bytes(): ArrayBuffer | undefined {
    if (!this.bodyAvailable()) {
      return undefined
    }
    return this.body?.data!
  }
}

export class ResponseBody {
  readonly data: ArrayBuffer | undefined
  readonly contentTypeString: string
  readonly contentLength: number

  constructor(responseBody: ArkResponseBody) {
    this.data = responseBody.data
    this.contentTypeString = responseBody.contentTypeString
    this.contentLength = responseBody.contentLength
  }
}

export class HttpError extends Error {
  responseBody?: ResponseBody | undefined
  code?: HttpStatusCode

  constructor(code: HttpStatusCode, responseBody: ResponseBody | undefined) {
    super()
    this.code = code
    this.responseBody = responseBody
  }
}
