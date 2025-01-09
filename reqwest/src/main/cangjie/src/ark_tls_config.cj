/**
 * Created on 2025/1/9
 */
package ohos_app_cangjie_OkRequest

import ohos.ark_interop.*
import ohos.ark_interop_macro.*

@Interop[ArkTS]
public class ArkTlsConfig {
	let verifyMode: String
    let pem: Option<String>
    public init(verifyMode: String, pem: Option<String>) {
    	this.verifyMode = verifyMode
        this.pem = pem
    }
}