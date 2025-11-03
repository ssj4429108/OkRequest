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

  toEventSource(onMessage : (msg: string) => void, onError?: (err: any) => void){
    let requestBuilder = new RequestBuilder(this)
    requestBuilder.
  }

  head(url: string): RequestBuilder {
    let requestBuilder = new RequestBuilder(this)
    requestBuilder.url = this.generateUrl(url)
    requestBuilder.method = HttpMethod.HEAD
    return requestBuilder
  }


  async execute(request: Request, signal?: any): Promise<Response | undefined> {
    this.checkLoadedSO()

    this.config.requestInterceptors.forEach((interceptor) => {
      request = interceptor.intercept(request)
    })
    request.url = this.generateUrl(request.url)

    let realRequest = await request.toRealRequest(callback)

    // this.requestCache.set(request.requestId, realRequest)

    let result = await this.send(request, realRequest, signal)

    this.config.responseInterceptors.forEach((interceptor) => {
      result = interceptor.intercept(result)
    })
    return result
  }

  async sse(request: Request, onMessage: (msg: string) => void, onError?: (err: any) => void,
    signal?: any): Promise<void> {
    var isCancel = false
    this.checkLoadedSO()
    if (signal) {
      signal.addEventListener(('abort'), () => {
        isCancel = true
        throw Error('request aborted by signal.')
      })
    }
    this.config.requestInterceptors.forEach((interceptor) => {
      request = interceptor.intercept(request)
    })
    request.url = this.generateUrl(request.url)
    let realRequest = await request.toRealRequest()

    return new Promise<void>((resolve, reject) => {
      try {
        this.client.sse(realRequest, (err: Error | null, arg: string) => {
          if (err) {
            if (onError) {
              try {
                if (!isCancel) {
                  onError(err)
                }
              } catch (e) {
              }
            }
            reject(err)
          } else {
            try {
              if (!isCancel) {
                onMessage(arg)
              }
            } catch (e) {
            }
          }
        }).then(() => {
          resolve()
        }).catch((e: any) => {
          if (onError && !isCancel) {
            try {
              onError(e)
            } catch (ee) {
            }
          }
          reject(e)
        })
      } catch (e) {
        if (onError && !isCancel) {
          try {
            onError(e)
          } catch (ee) {
          }
        }
        reject(e)
      }
    })
  }

  protected async send(request: Request, realRequest: oh_request.ArkRequest,
    signal?: any): Promise<Response | undefined> {
    let result: oh_request.ArkResponse | undefined

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