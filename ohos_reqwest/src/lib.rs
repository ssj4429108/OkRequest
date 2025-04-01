use napi_derive_ohos::napi;
use napi_ohos::{bindgen_prelude::{BigInt, Buffer}, Error, Result};
use reqwest::Version;
use reqwest_middleware::{ClientBuilder, ClientWithMiddleware};
use std::{collections::HashMap, time::Duration};

#[napi(object)]
pub struct ArkRequest {
    pub url: String,
    pub method: String,
    pub headers: Option<HashMap<String, String>>,
    pub protocol: Option<String>,
    pub body: Option<Buffer>,
    pub dns: Option<HashMap<String, Vec<String>>>
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
        // let content_length = resp.content_length();
        // // hilog_info!(format!("content-length:{:?}", content_length));
        // // let body = if content_length.is_some() && content_length.unwrap() > 0 {
        // //     let res = resp.bytes().await.map_err(|e| Error::from_reason(e.to_string()))?; // 避免 `unwrap()`
            
        // // } else {
        // //     None
        // // };

        let res = resp.bytes().await.map_err(|e| Error::from_reason(format!("{:?}", e)))?;
        let content_length: u64 = res.len().try_into().unwrap();
        let body = Some(ArkResponseBody {
            body: Buffer::from(res.to_vec()), // 直接使用 `Buffer::from(res)`，避免 `to_vec()`
            content_length: BigInt::from(content_length),
        });
        
        let resp = ArkResponse {
            code: status.as_u16(),
            headers: if headers.is_empty() { None } else { Some(headers) },
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

#[napi]
impl ArkHttpClient {
    #[napi(constructor)]    
    pub fn new(config: Option<Config>) -> Self {
        ArkHttpClient {
            config: config.unwrap_or_else(|| Config::default())
        }
    }
    fn new_real_client(&self) -> Result<ClientWithMiddleware> {
        let timeout = self.config.timeout;
        let mut reqwest_client_builder = reqwest::Client::builder()
            .connect_timeout(Duration::from_secs(u64::from_ne_bytes(timeout.to_ne_bytes())))
            .read_timeout(Duration::from_secs(u64::from_ne_bytes(timeout.to_ne_bytes())))
            .danger_accept_invalid_certs(self.config.ignore_ssl.unwrap_or(false));

        if self.config.tls.is_some() {
            let default_cert = vec![];
            for cert in self.config.tls.as_ref().unwrap().ca_cert.as_ref().unwrap_or(&default_cert).iter() {
                if cert.ty.to_lowercase() ==  "pem" {
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
                let cert = self.config.tls.as_ref().unwrap().client_cert.as_ref().unwrap();
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
        
        //middleware
        let builder = ClientBuilder::new(reqwest_client);

        let client: ClientWithMiddleware = builder
            .build();
        Ok(client)
    }
    
    #[napi]
    pub async fn send(&self, request: ArkRequest) -> Result<ArkResponse> {
       
        let client= self.new_real_client()?;
        let mut real_request = match request.method.to_uppercase().as_str() {
            "GET" => client.get(request.url),
            "POST" => client.post(request.url),
            "PUT" => client.put(request.url),
            "DELETE" => client.delete(request.url),
            "PATCH" => client.patch(request.url),
            "HEAD" => client.head(request.url),
            _ => return Err(Error::from_reason("Unsupported method".to_string())),
        };

        if let Some(headers) = request.headers {
            for (key, value) in headers.iter() {
                real_request = real_request.header(key, value);
            }
        }

        if let Some(protocol) = request.protocol {
            let version = convert_protocol(&protocol).unwrap_or(Version::HTTP_11);
            real_request = real_request.version(version);
        }

        if let Some(body) = request.body {
            let body = body.to_vec();
            real_request = real_request.body(reqwest::Body::from(body));
        }
        
        let resp = real_request
            .send()
            .await
            .map_err(|e| {
                let err_str = format!("{:?}", e);
                Error::from_reason(err_str)
            })?;
        
        let ark_resp = ArkResponse::new(resp).await?;
    
        Ok(ark_resp)
    }
}
