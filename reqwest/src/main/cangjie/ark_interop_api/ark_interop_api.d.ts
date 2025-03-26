export declare class ArkTlsConfig {
}

export declare class ArkResponseBody {
    data: ArrayBuffer | undefined
    contentTypeString: string
    contentLength: number
}

export declare class ArkResponse {
    url: string
    code: number
    body: ArkResponseBody | undefined
    message: string
    headers: string | undefined
    isSuccess: boolean
}

export declare class ArkRequest {
}

export declare class ArkHeader {
    name: string
    value: string
}

export declare class ArkHttpClient {
}

export declare class ArkCacheControl {
}

export declare interface CustomLib {
    ArkCacheControl: {new (noCacheBuild: boolean, noStoreBuild: boolean, maxAgeSeconds: number, maxStaleSeconds: number, minFreshSeconds: number, onlyIfCachedBuild: boolean, noTransformBuild: boolean, immutableBuild: boolean): ArkCacheControl}
    ArkHttpClient: {new (timeout: number, maxConnections: number, protocols: Array<string> | undefined, arkTlsConfig: ArkTlsConfig | undefined): ArkHttpClient}
    ArkHeader: {new (name: string, value: string): ArkHeader}
    send(client: ArkHttpClient, request: ArkRequest): Promise<ArkResponse | undefined>
    sendSync(client: ArkHttpClient, request: ArkRequest): ArkResponse | undefined
    cancel(request: ArkRequest): void
    ArkRequest: {new (url: string, method: string | undefined, headers: Array<ArkHeader> | undefined, mediaType: string | undefined, body: ArrayBuffer | undefined, dns: string | undefined, arkCacheControl: ArkCacheControl | undefined): ArkRequest}
    ArkResponse: {new (url: string, protocol: string, code: number, headers: string | undefined, body: ArkResponseBody | undefined, message: string): ArkResponse}
    ArkResponseBody: {new (contentType: string, contentLength: number, data: ArrayBuffer | undefined): ArkResponseBody}
    ArkTlsConfig: {new (verifyMode: string, pem: string | undefined): ArkTlsConfig}
}