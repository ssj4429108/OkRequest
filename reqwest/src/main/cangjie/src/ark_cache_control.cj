/**
 * Created on 2025/3/11
 */
package ohos_app_cangjie_OkRequest

import ohos.ark_interop.*
import ohos.ark_interop_macro.*

@Interop[ArkTS]
public class ArkCacheControl {
    let noCacheBuild: Bool

    let noStoreBuild: Bool

    let maxAgeSeconds: Int64

    let maxStaleSeconds: Int64

    let minFreshSeconds: Int64

    let onlyIfCachedBuild: Bool

    let noTransformBuild: Bool

    let immutableBuild: Bool

    public init(noCacheBuild: Bool, noStoreBuild: Bool, maxAgeSeconds: Int64, maxStaleSeconds: Int64, minFreshSeconds: Int64,
        onlyIfCachedBuild: Bool, noTransformBuild: Bool, immutableBuild: Bool) {
        this.noCacheBuild = noCacheBuild
        this.noStoreBuild = noStoreBuild
        this.maxAgeSeconds = maxAgeSeconds
        this.maxStaleSeconds = maxStaleSeconds
        this.minFreshSeconds = minFreshSeconds
        this.onlyIfCachedBuild = onlyIfCachedBuild
        this.noTransformBuild = noTransformBuild
        this.immutableBuild = immutableBuild
    }
}
