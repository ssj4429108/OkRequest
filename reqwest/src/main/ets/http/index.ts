import { ArkHttpClient, ArkRequest, ArkResponse, ArkHeader, CustomLib } from "ok_reqwest_api.so";
import { requireCJLib } from "libark_interop_loader.so";
import { HttpError, HttpMethod, OkConfig, Request, RequestBuilder, Response } from "./typings";

export class OkHttpClient {
  protected  baseApi: CustomLib | undefined;
  protected client: ArkHttpClient | undefined;

  private requestCache: Map<string, ArkRequest> = new Map()

  private config: OkConfig

  constructor(config: OkConfig) {
    this.baseApi = requireCJLib('libohos_app_cangjie_base.so') as CustomLib
    this.client = new this.baseApi.ArkHttpClient(config.timeout, config.maxConnections)
    this.config = config
  }

  private generateUrl(url: string): string {
    let targetUrl = undefined
    if (this.config.baseUrl) {
      if (url.startsWith("http")) {
        targetUrl = url
      } else {
        targetUrl = `${this.config.baseUrl}/${url}`
      }
    } else {
      targetUrl = url
    }
    return targetUrl
  }

  get(url: string): RequestBuilder {
    let requestBuilder = new RequestBuilder(this)
    requestBuilder.url = this.generateUrl(url)
    requestBuilder.method = HttpMethod.GET
    return requestBuilder
  }

  post(url: string): RequestBuilder {
    let requestBuilder = new RequestBuilder(this)
    requestBuilder.url = this.generateUrl(url)
    requestBuilder.method = HttpMethod.POST
    return requestBuilder
  }

  put(url: string): RequestBuilder {
    let requestBuilder = new RequestBuilder(this)
    requestBuilder.url = this.generateUrl(url)
    requestBuilder.method = HttpMethod.PUT
    return requestBuilder
  }

  patch(url: string): RequestBuilder {
    let requestBuilder = new RequestBuilder(this)
    requestBuilder.url = this.generateUrl(url)
    requestBuilder.method = HttpMethod.PATCH
    return requestBuilder
  }

  delete(url: string): RequestBuilder {
    let requestBuilder = new RequestBuilder(this)
    requestBuilder.url = this.generateUrl(url)
    requestBuilder.method = HttpMethod.DELETE
    return requestBuilder
  }

  head(url: string): RequestBuilder {
    let requestBuilder = new RequestBuilder(this)
    requestBuilder.url = this.generateUrl(url)
    requestBuilder.method = HttpMethod.HEAD
    return requestBuilder
  }

  createHeader(name: string, value: string): ArkHeader {
    return new this.baseApi!.ArkHeader(name, value)
  }

  private createRealRequest(request: Request): ArkRequest {
    let realRequest = new this.baseApi!.ArkRequest(
      request.url,
      request.method?.valueOf() || undefined,
      request.headers,
      request.mediaType? request.mediaType : "application/json; charset=utf-8",
      request.body
    )
    return realRequest
  }

  async execute(request: Request): Promise<Response | undefined> {
    this.checkLoadedSO()

    this.config.requestInterceptors.forEach((interceptor) => {
      request = interceptor.intercept(request)
    })

    let realRequest = this.createRealRequest(request)
    this.requestCache.set(request.requestId, realRequest)

    let result = await this.send(request, realRequest)

    this.config.responseInterceptors.forEach((interceptor) => {
      result = interceptor.intercept(result)
    })
    return result
  }

  protected  async send(request: Request, realRequest: ArkRequest): Promise<Response | undefined> {
    let result: ArkResponse | undefined
    try {
      result = await this.baseApi!.send(this.client, realRequest)
    } catch (e) {
      throw e
    }
    if (!result) return undefined
    let response = new Response(result, request)
    if (!response.successfully) {
      throw new HttpError(response.code, response.body)
    }
    return response
  }

  private checkLoadedSO() {
    if (!this.baseApi) {
      throw new SyntaxError('need loaded base_api.so')
    }
  }

  cancelAll() {
    this.requestCache.forEach((request) => {
      this.cancelRequest(request)
    })
  }

  cancel(request: Request) {
    let realRequest = this.requestCache.get(request.requestId)
    if (!realRequest) {
      return
    }
    this.cancelRequest(realRequest)
  }

  private cancelRequest(request: ArkRequest) {
    this.checkLoadedSO()
    this.baseApi!.cancel(request)
  }
}