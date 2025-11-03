use futures::stream::StreamExt;
use hilog_binding::hilog_debug;
use http::Extensions;
use http_cache_reqwest::{
    CACacheManager, Cache, CacheMode as HttpCacheMode, HttpCache, HttpCacheOptions,
};
use napi_derive_ohos::napi;
use napi_ohos::threadsafe_function::ThreadsafeFunction;
use napi_ohos::{
    bindgen_prelude::{BigInt, Buffer},
    Error, Result,
};

use reqwest::{Client, Version};
use reqwest_middleware::{ClientBuilder, ClientWithMiddleware, Middleware, Next};
use reqwest_retry::{policies::ExponentialBackoff, RetryTransientMiddleware};
use std::{collections::HashMap, time::Duration};

#[napi(object)]
#[derive(Clone)]
pub struct ArkRequest {
    pub url: String,
    pub method: String,
    pub headers: Option<HashMap<String, String>>,
    pub protocol: Option<String>,
    pub body: Option<Buffer>,
    pub dns: Option<HashMap<String, Vec<String>>>,
    pub cache_option: Option<CacheOption>,
    pub is_eventsource: Option<bool>,
}

#[napi]
#[derive(Debug, Default, Clone, Copy, PartialEq, Eq)]
pub enum CacheMode {
    /// Will inspect the HTTP cache on the way to the network.
    /// If there is a fresh response it will be used.
    /// If there is a stale response a conditional request will be created,
    /// and a normal request otherwise.
    /// It then updates the HTTP cache with the response.
    /// If the revalidation request fails (for example, on a 500 or if you're offline),
    /// the stale response will be returned.
    #[default]
    Default,
    /// Behaves as if there is no HTTP cache at all.
    NoStore,
    /// Behaves as if there is no HTTP cache on the way to the network.
    /// Ergo, it creates a normal request and updates the HTTP cache with the response.
    Reload,
    /// Creates a conditional request if there is a response in the HTTP cache
    /// and a normal request otherwise. It then updates the HTTP cache with the response.
    NoCache,
    /// Uses any response in the HTTP cache matching the request,
    /// not paying attention to staleness. If there was no response,
    /// it creates a normal request and updates the HTTP cache with the response.
    ForceCache,
    /// Uses any response in the HTTP cache matching the request,
    /// not paying attention to staleness. If there was no response,
    /// it returns a network error.
    OnlyIfCached,
    /// Overrides the check that determines if a response can be cached to always return true on 200.
    /// Uses any response in the HTTP cache matching the request,
    /// not paying attention to staleness. If there was no response,
    /// it creates a normal request and updates the HTTP cache with the response.
    IgnoreRules,
}

#[napi(object)]
#[derive(Clone)]
pub struct CacheOption {
    pub cache_mode: CacheMode,
}

#[napi]
pub fn to_curl(request: ArkRequest) -> Result<String> {
    let curl = request.to_curl_command();
    Ok(curl)
}

#[napi(object)]
#[derive(Clone)]
pub struct ArkResponse {
    pub code: u16,
    pub headers: Option<HashMap<String, String>>,
    pub body: Option<ArkResponseBody>,
    pub protocol: String,
    pub message: String,
}

#[napi(object)]
#[derive(Clone)]
pub struct ArkResponseBody {
    pub body: Buffer,
    pub content_length: BigInt,
}

trait CurlCommand {
    fn to_curl_command(&self) -> String;
}

impl CurlCommand for ArkRequest {
    fn to_curl_command(&self) -> String {
        let method = self.method.as_str();
        let url = self.url.as_str();
        let headers = self.headers.clone();

        // 构造 `curl` 命令
        let mut curl_cmd = format!("curl -X {}", method);
        curl_cmd.push_str(&format!(" '{}'", url));

        // 添加 Headers
        if let Some(headers) = headers {
            for (key, value) in headers.iter() {
                curl_cmd.push_str(&format!(" -H '{}: {}'", key, value));
            }
        }

        // 添加 Body（如果存在）
        if let Some(body) = &self.body {
            let vec = body.to_vec();
            let bytes = vec.as_slice();
            let body_str = String::from_utf8_lossy(bytes);
            curl_cmd.push_str(&format!(" -d '{}'", body_str));
        }
        curl_cmd
    }
}

impl CurlCommand for reqwest::Request {
    fn to_curl_command(&self) -> String {
        let method = self.method().as_str();
        let url = self.url().as_str();
        let headers = self.headers();
        let body = self.body();

        // 构造 `curl` 命令
        let mut curl_cmd = format!("curl -X {}", method);
        curl_cmd.push_str(&format!(" '{}'", url));

        // 添加 Headers
        for (key, value) in headers.iter() {
            curl_cmd.push_str(&format!(" -H '{}: {}'", key, value.to_str().unwrap_or("")));
        }

        // 添加 Body（如果存在）
        if let Some(body) = body {
            if let Some(bytes) = body.as_bytes() {
                let body_str = String::from_utf8_lossy(bytes);
                curl_cmd.push_str(&format!(" -d '{}'", body_str));
            }
        }
        curl_cmd
    }
}

impl ArkResponse {
    async fn new(resp: reqwest::Response) -> Result<ArkResponse> {
        let status = resp.status();
        let version = format!("{:?}", resp.version());

        let mut headers = HashMap::new();
        for (key, value) in resp.headers().iter() {
            if let Ok(val) = value.to_str() {
                headers.insert(key.to_string(), val.to_string());
            }
        }

        let res = resp
            .bytes()
            .await
            .map_err(|e| Error::from_reason(format!("{:?}", e)))?;
        let content_length: u64 = res.len().try_into().unwrap();
        let body = Some(ArkResponseBody {
            body: Buffer::from(res.to_vec()), // 直接使用 `Buffer::from(res)`，避免 `to_vec()`
            content_length: BigInt::from(content_length),
        });

        let resp = ArkResponse {
            code: status.as_u16(),
            headers: if headers.is_empty() {
                None
            } else {
                Some(headers)
            },
            body: body,
            protocol: version,
            message: status.canonical_reason().unwrap_or("Unknown").to_string(), // 避免 `unwrap()`
        };
        Ok(resp)
    }
}

#[napi(object)]
#[derive(Clone)]
pub struct Cert {
    pub cert: String,
    pub ty: String,
}

#[napi(object)]
#[derive(Clone)]
pub struct TlsConfig {
    pub ca_cert: Option<Vec<Cert>>,
    pub client_cert: Option<String>,
}

#[napi(object)]
#[derive(Clone)]
pub struct Config {
    pub timeout: i64,
    pub tls: Option<TlsConfig>,
    pub ignore_ssl: Option<bool>,
    pub force_rustls_ssl: Option<bool>,
    pub no_proxy: Option<bool>,
    pub enable_curl_log: Option<bool>,
}

#[napi]
impl Default for Config {
    fn default() -> Config {
        Config {
            timeout: 10,
            tls: None,
            ignore_ssl: None,
            force_rustls_ssl: None,
            no_proxy: None,
            enable_curl_log: None,
        }
    }
}

#[napi]
#[derive(Clone)]
pub struct ArkHttpClient {
    pub config: Config,
}
fn convert_protocol(protocol: &str) -> Result<Version> {
    match protocol {
        "HTTP/0.9" => Ok(Version::HTTP_09),
        "HTTP/1.0" => Ok(Version::HTTP_10),
        "HTTP/1.1" => Ok(Version::HTTP_11),
        "HTTP/2.0" => Ok(Version::HTTP_2),
        "HTTP/3.0" => Ok(Version::HTTP_3),
        _ => Err(Error::from_reason("Invalid HTTP version")),
    }
}

pub struct CurlLoggerMiddleware;

#[async_trait::async_trait]
impl Middleware for CurlLoggerMiddleware {
    async fn handle(
        &self,
        request: reqwest::Request,
        extensions: &mut Extensions,
        next: Next<'_>,
    ) -> reqwest_middleware::Result<reqwest::Response> {
        let curl_cmd = &request.to_curl_command();

        hilog_debug!(format!("CURL Command: {}", curl_cmd));

        // 继续执行请求
        let res = next.run(request, extensions).await;
        res
    }
}

#[napi]
impl ArkHttpClient {
    #[napi(constructor)]
    pub fn new(config: Option<Config>) -> Self {
        ArkHttpClient {
            config: config.unwrap_or_else(|| Config::default()),
        }
    }

    fn new_real_origin_client(&self) -> Result<Client> {
        let timeout = self.config.timeout;
        let mut reqwest_client_builder = reqwest::Client::builder()
            .connect_timeout(Duration::from_secs(u64::from_ne_bytes(
                timeout.to_ne_bytes(),
            )))
            .read_timeout(Duration::from_secs(u64::from_ne_bytes(
                timeout.to_ne_bytes(),
            )))
            .danger_accept_invalid_certs(self.config.ignore_ssl.unwrap_or(false));

        if self.config.tls.is_some() {
            let default_cert = vec![];
            for cert in self
                .config
                .tls
                .as_ref()
                .unwrap()
                .ca_cert
                .as_ref()
                .unwrap_or(&default_cert)
                .iter()
            {
                if cert.ty.to_lowercase() == "pem" {
                    if let Ok(cert) = reqwest::Certificate::from_pem(cert.cert.as_bytes()) {
                        reqwest_client_builder = reqwest_client_builder.add_root_certificate(cert);
                    }
                } else if cert.ty.to_lowercase() == "der" {
                    if let Ok(cert) = reqwest::Certificate::from_der(cert.cert.as_bytes()) {
                        reqwest_client_builder = reqwest_client_builder.add_root_certificate(cert);
                    }
                }
            }
            //client identity
            if self.config.tls.as_ref().unwrap().client_cert.is_some() {
                let cert = self
                    .config
                    .tls
                    .as_ref()
                    .unwrap()
                    .client_cert
                    .as_ref()
                    .unwrap();
                if let Ok(cert) = reqwest::Identity::from_pem(cert.as_bytes()) {
                    reqwest_client_builder = reqwest_client_builder.identity(cert);
                }
            }
        }
        if self.config.force_rustls_ssl.unwrap_or(false) {
            reqwest_client_builder = reqwest_client_builder.use_rustls_tls();
        }
        if self.config.no_proxy.unwrap_or(false) {
            reqwest_client_builder = reqwest_client_builder.no_proxy();
        }
        // reqwest_client_builder.
        let reqwest_client = reqwest_client_builder
            .build()
            .map_err(|e| Error::from_reason(e.to_string()))?;
        Ok(reqwest_client)
    }
    fn new_real_client(&self, request: &ArkRequest) -> Result<ClientWithMiddleware> {
        let timeout = self.config.timeout;
        let mut reqwest_client_builder = reqwest::Client::builder()
            .connect_timeout(Duration::from_secs(u64::from_ne_bytes(
                timeout.to_ne_bytes(),
            )))
            .read_timeout(Duration::from_secs(u64::from_ne_bytes(
                timeout.to_ne_bytes(),
            )))
            .danger_accept_invalid_certs(self.config.ignore_ssl.unwrap_or(false));

        if self.config.tls.is_some() {
            let default_cert = vec![];
            for cert in self
                .config
                .tls
                .as_ref()
                .unwrap()
                .ca_cert
                .as_ref()
                .unwrap_or(&default_cert)
                .iter()
            {
                if cert.ty.to_lowercase() == "pem" {
                    if let Ok(cert) = reqwest::Certificate::from_pem(cert.cert.as_bytes()) {
                        reqwest_client_builder = reqwest_client_builder.add_root_certificate(cert);
                    }
                } else if cert.ty.to_lowercase() == "der" {
                    if let Ok(cert) = reqwest::Certificate::from_der(cert.cert.as_bytes()) {
                        reqwest_client_builder = reqwest_client_builder.add_root_certificate(cert);
                    }
                }
            }
            //client identity
            if self.config.tls.as_ref().unwrap().client_cert.is_some() {
                let cert = self
                    .config
                    .tls
                    .as_ref()
                    .unwrap()
                    .client_cert
                    .as_ref()
                    .unwrap();
                if let Ok(cert) = reqwest::Identity::from_pem(cert.as_bytes()) {
                    reqwest_client_builder = reqwest_client_builder.identity(cert);
                }
            }
        }
        if self.config.force_rustls_ssl.unwrap_or(false) {
            reqwest_client_builder = reqwest_client_builder.use_rustls_tls();
        }
        if self.config.no_proxy.unwrap_or(false) {
            reqwest_client_builder = reqwest_client_builder.no_proxy();
        }
        // reqwest_client_builder.
        let reqwest_client = reqwest_client_builder
            .build()
            .map_err(|e| Error::from_reason(e.to_string()))?;

        let retry_policy = ExponentialBackoff::builder().build_with_max_retries(3);

        //middleware
        let mut builder = ClientBuilder::new(reqwest_client)
            .with(RetryTransientMiddleware::new_with_policy(retry_policy));

        if let Some(cache_option) = &request.cache_option {
            // cache
            let mode: HttpCacheMode = match cache_option.cache_mode {
                CacheMode::Default => HttpCacheMode::Default,
                CacheMode::NoStore => HttpCacheMode::NoStore,
                CacheMode::Reload => HttpCacheMode::Reload,
                CacheMode::NoCache => HttpCacheMode::NoCache,
                CacheMode::ForceCache => HttpCacheMode::ForceCache,
                CacheMode::OnlyIfCached => HttpCacheMode::OnlyIfCached,
                CacheMode::IgnoreRules => HttpCacheMode::IgnoreRules,
            };
            builder = builder.with(Cache(HttpCache {
                mode: mode,
                manager: CACacheManager::default(),
                options: HttpCacheOptions::default(),
            }));
        }

        //curl log
        if self.config.enable_curl_log.unwrap_or(false) {
            builder = builder.with(CurlLoggerMiddleware);
        }

        let client: ClientWithMiddleware = builder.build();
        Ok(client)
    }

    #[napi]
    pub async fn send(
        &self,
        request: ArkRequest,
        cb: Option<ThreadsafeFunction<String, ()>>,
    ) -> Result<ArkResponse> {
        if request.is_eventsource.unwrap_or(false) {
            match cb {
                Some(cb) => {
                    let client = self.new_real_origin_client()?;
                    let real_request = self.build_request_for_client(client, &request)?;

                    let mut es = reqwest_eventsource::EventSource::new(real_request).unwrap();

                    while let Some(event) = es.next().await {
                        match event {
                            Ok(reqwest_eventsource::Event::Open) => println!("Connection Open!"),
                            Ok(reqwest_eventsource::Event::Message(message)) => {
                                cb.call(
                                    Ok(format!("{}", message.data)),
                                    napi_ohos::threadsafe_function::ThreadsafeFunctionCallMode::NonBlocking,
                                );
                            }
                            Err(err) => {
                                println!("Error: {}", err);
                                es.close();
                                cb.call(
                                    Err(Error::from_reason(format!("{}", err))),
                                    napi_ohos::threadsafe_function::ThreadsafeFunctionCallMode::NonBlocking,
                                );
                                return Err(Error::from_reason(format!("{}", err)));
                            }
                        }
                    }
                    Ok(ArkResponse {
                        code: 200,
                        headers: None,
                        body: None,
                        protocol: "HTTP/1.1".to_string(),
                        message: "OK".to_string(),
                    })
                }
                None => {
                    return Err(Error::from_reason(
                        "Callback function is required for EventSource".to_string(),
                    ));
                }
            }
        } else {
            let client = self.new_real_client(&request)?;
            let real_request = self.build_request_for_middleware(client, &request)?;

            let resp = real_request.send().await.map_err(|e| {
                let err_str = format!("{:?}", e);
                Error::from_reason(err_str)
            })?;

            let ark_resp = ArkResponse::new(resp).await?;
            Ok(ark_resp)
        }
    }

    // 提取构建请求的公共方法 for Client
    fn build_request_for_client(
        &self,
        client: Client,
        request: &ArkRequest,
    ) -> Result<reqwest::RequestBuilder> {
        let mut real_request = match request.method.to_uppercase().as_str() {
            "GET" => client.get(&request.url),
            "POST" => client.post(&request.url),
            "PUT" => client.put(&request.url),
            "DELETE" => client.delete(&request.url),
            "PATCH" => client.patch(&request.url),
            "HEAD" => client.head(&request.url),
            _ => return Err(Error::from_reason("Unsupported method".to_string())),
        };

        if let Some(headers) = &request.headers {
            for (key, value) in headers.iter() {
                real_request = real_request.header(key, value);
            }
        }

        if let Some(protocol) = &request.protocol {
            let version = convert_protocol(protocol).unwrap_or(Version::HTTP_11);
            real_request = real_request.version(version);
        }

        if let Some(body) = &request.body {
            let body = body.to_vec();
            real_request = real_request.body(reqwest::Body::from(body));
        }

        Ok(real_request)
    }

    // 提取构建请求的公共方法 for ClientWithMiddleware
    fn build_request_for_middleware(
        &self,
        client: ClientWithMiddleware,
        request: &ArkRequest,
    ) -> Result<reqwest_middleware::RequestBuilder> {
        let mut real_request = match request.method.to_uppercase().as_str() {
            "GET" => client.get(&request.url),
            "POST" => client.post(&request.url),
            "PUT" => client.put(&request.url),
            "DELETE" => client.delete(&request.url),
            "PATCH" => client.patch(&request.url),
            "HEAD" => client.head(&request.url),
            _ => return Err(Error::from_reason("Unsupported method".to_string())),
        };

        if let Some(headers) = &request.headers {
            for (key, value) in headers.iter() {
                real_request = real_request.header(key, value);
            }
        }

        if let Some(protocol) = &request.protocol {
            let version = convert_protocol(protocol).unwrap_or(Version::HTTP_11);
            real_request = real_request.version(version);
        }

        if let Some(body) = &request.body {
            let body = body.to_vec();
            real_request = real_request.body(reqwest::Body::from(body));
        }

        Ok(real_request)
    }
}
