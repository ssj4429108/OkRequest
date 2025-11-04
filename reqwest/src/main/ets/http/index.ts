import { EventSourceCallback, HttpError, HttpMethod, OkConfig, Request, RequestBuilder, Response } from "./typings";
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
      tls: tlsConfig,
      enableCurlLog: config.enableCurlLog,
      ignoreSsl: config.tlsConfig?.ignoreSsl ?? false
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

  toEventSource() {
    let requestBuilder = new RequestBuilder(this)
    requestBuilder.isEventsource = true
  }

  head(url: string): RequestBuilder {
    let requestBuilder = new RequestBuilder(this)
    requestBuilder.url = this.generateUrl(url)
    requestBuilder.method = HttpMethod.HEAD
    return requestBuilder
  }


  async execute(request: Request): Promise<Response | undefined> {
    this.checkLoadedSO()

    this.config.requestInterceptors.forEach((interceptor) => {
      request = interceptor.intercept(request)
    })
    request.url = this.generateUrl(request.url)

    let realRequest = await request.toRealRequest()

    // this.requestCache.set(request.requestId, realRequest)

    let result = await this.send(request, realRequest)

    this.config.responseInterceptors.forEach((interceptor) => {
      result = interceptor.intercept(result)
    })
    return result
  }

  protected async send(request: Request, realRequest: oh_request.ArkRequest): Promise<Response | undefined> {
    let result: oh_request.ArkResponse | undefined
    let signal = request.signal
    console.log('send request: ------------- ', realRequest.isEventsource)
    if (request.isEventsource) {
      var isCancel = false

      if (signal) {
        signal.addEventListener(('abort'), () => {
          isCancel = true
          throw Error('request aborted by signal.')
        })
      }
      result = await this.client?.sendWithCallback(realRequest, (err: Error | null, msg: string) => {
        console.log('send request: ------------- ', msg)
        if (err) {
          if (request.eventSourceCallback?.onError && !isCancel) {
            request.eventSourceCallback?.onError(err)
          }
        } else {
          if (!isCancel) {
            request.eventSourceCallback?.onMessage(msg)
          }
        }
      })
    } else {
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