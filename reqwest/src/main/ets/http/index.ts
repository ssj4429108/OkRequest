import { HttpError, HttpMethod, OkConfig, Request, RequestBuilder, Response } from "./typings";
import oh_request from 'libohos_reqwest.so'
import { buffer } from "@kit.ArkTS";

export class OkHttpClient {
  protected client: oh_request.ArkHttpClient | undefined;


  private config: OkConfig

  constructor(config: OkConfig) {
    let tlsConfig: oh_request.TlsConfig | undefined = undefined
    if (config.tlsConfig) {
      tlsConfig = {
        clientCert: config.tlsConfig.clientCert,
        caCert: config.tlsConfig.caCert?.map((item) => {
          return {
            cert: item.cert,
            ty: item.ty
          }
        }) ?? []
      }
    }

    let clientConfig: oh_request.Config = {
      timeout: config.timeout,
      tls: tlsConfig
    }
    this.client =
      new oh_request.ArkHttpClient(clientConfig)
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

  private async createRealRequest(request: Request): Promise<oh_request.ArkRequest> {
    let body = await request.body?.bytes() || undefined
    let realRequest: oh_request.ArkRequest = {
      url: this.generateUrl(request.url),
      method: request.method,
      headers: request.headers,
      body: body ? buffer.from(body).buffer : undefined,
      dns: undefined
    }
    return realRequest
  }

  async execute(request: Request, single?: any): Promise<Response | undefined> {
    this.checkLoadedSO()

    this.config.requestInterceptors.forEach((interceptor) => {
      request = interceptor.intercept(request)
    })

    let realRequest = await this.createRealRequest(request)
    // this.requestCache.set(request.requestId, realRequest)

    let result = await this.send(request, realRequest, single)

    this.config.responseInterceptors.forEach((interceptor) => {
      result = interceptor.intercept(result)
    })
    return result
  }

  protected async send(request: Request, realRequest: oh_request.ArkRequest, signal?: any): Promise<Response | undefined> {
    let result: oh_request.ArkResponse | undefined
    if (signal) {
      signal.addEventListener(('abort'), () => {
        throw Error('request aborted by signal.')
      })
    }
    try {
      result = await this.client.send(realRequest)
    } catch (e) {
      throw e
    }
    if (!result) {
      return undefined
    }
    let response = new Response(result, request)
    if (!response.successfully) {
      throw new HttpError(request, response.code, response.body)
    }
    return response
  }

  private checkLoadedSO() {
    if (!this.client) {
      throw new SyntaxError('need loaded libohos_reqwest.so')
    }
  }
}