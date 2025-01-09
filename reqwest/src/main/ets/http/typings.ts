import { ArkResponse, ArkResponseBody, ArkHeader } from "ok_request_api.so"
import util from '@ohos.util'
import { OkHttpClient } from "."
import { JSON } from "@kit.ArkTS"
import { fileIo as fs, ReadOptions } from '@kit.CoreFileKit'
import systemDateTime from "@ohos.systemDateTime"
import { ByteArrayStream } from "../stream"
import { socket } from "@kit.NetworkKit"


export interface RequestInterceptor {
  intercept: (request: Request) => Request
}

export interface ResponseInterceptor {
  intercept: (response: Response | undefined) => Response | undefined
}

export enum Protocol {
  HTTP_1_0 = 'http/1.0',
  HTTP_1_1 = 'http/1.1',
  HTTP_2 = 'h2',
  H2_PRIOR_KNOWLEDGE = 'h2_prior_knowledge'
}

export enum VerifyMode {
  DEFAULT = 'Default',
  ALL = 'All',
  CUSTOM = 'Custom'
}

export interface TlsConfig {
  verifyMode: VerifyMode | VerifyMode.DEFAULT
  pem: string | undefined
}

// export interface Dns {
//   lookup: (domain: string) => Array<socket.NetAddress>
// }

export interface OkConfig {
  requestInterceptors: RequestInterceptor[]
  responseInterceptors: ResponseInterceptor[]
  timeout: number
  maxConnections: number
  baseUrl: string | undefined

  protocols: Array<Protocol> | undefined

  tlsConfig: TlsConfig | undefined

  // dns: Dns | undefined
}

// class OkConfigImpl implements OkConfig {
//   readonly requestInterceptors: RequestInterceptor[] = []
//   readonly responseInterceptors: ResponseInterceptor[] = []
//   readonly timeout: number
//   readonly maxConnections: number
//   baseUrl: string | undefined
//
//   readonly protocols: Array<Protocol> | undefined
//
//   readonly tlsConfig: TlsConfig | undefined
//
//   readonly dns: Dns | undefined
//
//   constructor(timeout: number = 30, maxConnections: number = 5, protocols: Array<Protocol> | undefined = undefined,
//     tlsConfig: TlsConfig | undefined = undefined,
//     dns: Dns | undefined = undefined) {
//     this.timeout = timeout
//     this.maxConnections = maxConnections
//     this.protocols = protocols
//     this.tlsConfig = tlsConfig
//     this.dns = dns
//   }
//
//   setBaseUrl(baseUrl: string) {
//     this.baseUrl = baseUrl
//   }
//
//   addRequestInterceptor(interceptor: (request: Request) => Request) {
//
//     function createInterceptor(): RequestInterceptor {
//       return {
//         intercept(request: Request): Request {
//           return interceptor.call(this, request)
//         }
//       }
//     }
//
//     this.requestInterceptors.push(createInterceptor())
//   }
//
//   addResponseInterceptor(interceptor: (response: Response) => Response) {
//
//     function createInterceptor(): ResponseInterceptor {
//       return {
//         intercept(response: Response | undefined): Response | undefined {
//           return interceptor.call(this, response)
//         }
//       }
//     }
//
//     this.responseInterceptors.push(createInterceptor())
//   }
// }

export class Request {
  readonly url: string
  readonly method?: HttpMethod | undefined
  readonly headers: Array<ArkHeader> = []
  readonly mediaType?: string | undefined
  readonly body?: RequestBody | undefined

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

export interface RequestBody {
  contentType(): string | undefined

  contentLength(): number

  bytesSync(): ArrayBuffer

  bytes(): Promise<ArrayBuffer>
}

class TextRequestBody implements RequestBody {
  private data: string
  private originalType: string | undefined

  constructor(data: string, originalType: string | undefined = undefined) {
    this.data = data
    this.originalType = originalType
  }

  contentLength(): number {
    return this.bytesSync().byteLength
  }

  contentType(): string | undefined {
    return this.originalType
  }

  bytesSync(): ArrayBuffer {
    return this.string2BytesSync(this.data)
  }

  async bytes(): Promise<ArrayBuffer> {
    return await this.string2Bytes(this.data)
  }


  private string2BytesSync(data: string): ArrayBuffer {
    let encoder = util.TextEncoder.create('utf-8')
    let uint8Array = encoder.encodeInto(data)
    return uint8Array
  }

  private async string2Bytes(data: string): Promise<ArrayBuffer> {
    let encoder = util.TextEncoder.create('utf-8')
    let uint8Array = encoder.encodeInto(data)
    return uint8Array
  }
}

export class Part {
  body: RequestBody
  headers: Record<string, string> | undefined

  constructor(body: RequestBody, headers: Record<string, string> | undefined = undefined) {
    this.body = body
    this.headers = headers

  }

  static create(body: RequestBody, headers: Record<string, string> | undefined = undefined): Part {
    return new Part(body, headers)
  }

  static createFormData(name: string, fileName: string | undefined = undefined, body: RequestBody): Part {
    if (name.length <= 0) {
      throw Error('name is Empty')
    }
    let disposition
    if (fileName) {
      disposition =
        `form-data; name="${encodeURIComponent(String(name))}"; filename="${encodeURIComponent(String(fileName))}"`
    } else {
      disposition = `form-data; name="${encodeURIComponent(String(name))}"`
    }

    Part.checkName(name)
    let headers = {
      "Content-Disposition": disposition
    }
    return Part.create(body, headers)
  }

  private static checkName(name: string): void {
    for (let i = 0; i < name.length; i++) {
      const char = name.charAt(i); // 获取单个字符
      const charCode = char.charCodeAt(0); // 获取字符的 Unicode 编码

      // 检查字符的 Unicode 编码是否在合法范围外
      if (charCode <= 0x20 || charCode >= 0x7f) {
        throw new Error(`Unexpected char in header name: ${name}`);
      }
    }
  }
}

class MultipartBody implements RequestBody {
  parts: Part[] = []
  boundary: string
  originalType: string

  private CRLF: Uint8Array = this.stringToBytes('"\r\n"')

  private DASHDASH: Uint8Array = this.stringToBytes('--')

  private COLONSPACE: Uint8Array = this.stringToBytes(': ')

  constructor(parts: Part[], boundary: string, originalType: string) {
    this.parts = parts
    this.boundary = boundary
    this.originalType = originalType
  }

  contentLength(): number {
    return this.bytesSync().byteLength
  }

  contentType(): string {
    return this.originalType
  }

  bytesSync(): ArrayBuffer {
    let stream = new ByteArrayStream(new Uint8Array())
    this.parts.forEach((part) => {
      if (part.headers) {

        stream.writeBytes(this.DASHDASH)
        stream.writeBytes(this.stringToBytes(this.boundary))
        stream.writeBytes(this.CRLF)
        Object.entries(part.headers).forEach(([name, value]) => {
          stream.writeBytes(this.stringToBytes(name))
          stream.writeBytes(this.COLONSPACE)
          stream.writeBytes(this.stringToBytes(value))
        })
      }
      let body = part.body
      let contentType = body.contentType()
      if (contentType) {
        stream.writeBytes(this.stringToBytes('Content-Type: '))
        stream.writeBytes(this.stringToBytes(contentType))
        stream.writeBytes(this.CRLF)
      }
      let contentLength = body.contentLength()
      if (contentLength != -1) {
        stream.writeBytes(this.stringToBytes('Content-Length: '))
        stream.writeBytes(this.stringToBytes(`${contentLength}`))
        stream.writeBytes(this.CRLF)
      }
      stream.writeBytes(this.CRLF)

      //write body
      stream.writeBytes(new Uint8Array(body.bytesSync()))

      stream.writeBytes(this.CRLF)
    })

    stream.writeBytes(this.DASHDASH)
    stream.writeBytes(this.stringToBytes(this.boundary))
    stream.writeBytes(this.DASHDASH)
    stream.writeBytes(this.CRLF)

    return stream.readBytes(stream.getLength())
  }

  async bytes(): Promise<ArrayBuffer> {
    let stream = new ByteArrayStream(new Uint8Array())
    this.parts.forEach(async (part) => {
      if (part.headers) {

        stream.writeBytes(this.DASHDASH)
        stream.writeBytes(this.stringToBytes(this.boundary))
        stream.writeBytes(this.CRLF)
        Object.entries(part.headers).forEach(([name, value]) => {
          stream.writeBytes(this.stringToBytes(name))
          stream.writeBytes(this.COLONSPACE)
          stream.writeBytes(this.stringToBytes(value))
        })
      }
      let body = part.body
      let contentType = body.contentType()
      if (contentType) {
        stream.writeBytes(this.stringToBytes('Content-Type: '))
        stream.writeBytes(this.stringToBytes(contentType))
        stream.writeBytes(this.CRLF)
      }
      let contentLength = body.contentLength()
      if (contentLength != -1) {
        stream.writeBytes(this.stringToBytes('Content-Length: '))
        stream.writeBytes(this.stringToBytes(`${contentLength}`))
        stream.writeBytes(this.CRLF)
      }
      stream.writeBytes(this.CRLF)
      let bodyBuffer = await body.bytes()
      //write body
      stream.writeBytes(new Uint8Array(bodyBuffer))

      stream.writeBytes(this.CRLF)
    })

    stream.writeBytes(this.DASHDASH)
    stream.writeBytes(this.stringToBytes(this.boundary))
    stream.writeBytes(this.DASHDASH)
    stream.writeBytes(this.CRLF)
    return stream.readBytes(stream.getLength())
  }

  private stringToBytes(str: string): Uint8Array {
    const bytes = new Uint8Array(str.length);
    for (let i = 0; i < str.length; i++) {
      bytes[i] = str.charCodeAt(i);
    }
    return bytes;
  }

  builder(): MultipartBodyBuilder {
    return new MultipartBodyBuilder()
  }
}

export class MultipartBodyBuilder {
  parts: Part[] = []
  contentType = "multipart/mixed"
  boundary: string

  constructor() {
    this.boundary = `${systemDateTime.getTime()}`
  }

  addPart(body: RequestBody, headers: Record<string, string> | undefined = undefined): MultipartBodyBuilder {
    if (headers) {
      if (headers['Content-Type']) {
        throw Error('Unexpected header: Content-Type')
      }
      if (headers['Content-Length']) {
        throw Error('Unexpected header: Content-Length')
      }
    }
    this.parts.push(Part.create(body, headers))
    return this
  }

  addTextPart(value: string, headers: Record<string, string> | undefined = undefined): MultipartBodyBuilder {
    this.addPart(new TextRequestBody(value), headers)
    return this
  }

  addFormDataPart(name: string, fileName: string | undefined = undefined, body: RequestBody): MultipartBodyBuilder {
    this.parts.push(Part.createFormData(name, fileName, body))
    return this
  }

  addTextFormDataPart(name: string, value: string) {
    this.parts.push(Part.createFormData(name, "", new TextRequestBody(value)))
    return this
  }

  build(): MultipartBody {
    if (this.parts.length <= 0) {
      throw Error('Multipart body must have at least one part.')
    }
    return new MultipartBody(this.parts, this.boundary, this.contentType)
  }
}

export class FileBody implements RequestBody {
  readonly originalType: string
  private path: string

  constructor(path: string, originalType: string = 'application/octet-stream') {
    this.path = path
    this.originalType = originalType
  }

  contentLength(): number {
    return this.bytesSync().byteLength
  }

  contentType(): string {
    return this.originalType
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
  body?: RequestBody
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
    this.body = new TextRequestBody(this.toUrlencoded(form), 'application/x-www-form-urlencoded')
    return this
  }

  json(data: Record<string, any> | any): RequestBuilder {
    this.setHead('Content-Type', 'application/json; charset=utf-8')
    this.mediaType = 'application/json; charset=utf-8'
    this.body = new TextRequestBody(JSON.stringify(data), 'application/json; charset=utf-8')
    return this
  }

  file(fileBody: FileBody): RequestBuilder {
    this.setHead('Content-Type', fileBody.contentType())
    this.body = fileBody
    return this
  }

  multipart(multipartBody: MultipartBody): RequestBuilder {
    this.setHead('Content-Type', multipartBody.contentType())
    this.body = multipartBody
    return this
  }

  data(body: RequestBody, contentType: string): RequestBuilder {
    this.setHead('Content-Type', contentType)
    this.body = body
    return this
  }

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

  text(): string | undefined {
    return this.body?.text()
  }

  json<T>(): T | undefined {
    return this.body?.json<T>()
  }

  bytes(): ArrayBuffer | undefined {
    return this.body?.bytes()
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

  private bodyAvailable() {
    if (!this.data) {
      return false
    }
    let bin = this.data
    if (!bin) {
      return false
    }
    return true
  }

  text(): string | undefined {
    if (!this.bodyAvailable()) {
      return undefined
    }
    let bytes = this.data
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
    return this.data!
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
