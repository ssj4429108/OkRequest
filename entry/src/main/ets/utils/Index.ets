import { interactiveLiveness } from "@kit.VisionKit"
import { abilityAccessCtrl, common } from "@kit.AbilityKit"

export class  LivenessDetection {
  static async startLivenessDetection(context: common.UIAbilityContext): Promise<boolean> {
    if (!canIUse("SystemCapability.AI.Component.LivenessDetect")) {
      return false
    }
    let res = await abilityAccessCtrl.createAtManager().requestPermissionsFromUser(context, ['ohos.permission.CAMERA'])
    for (let i = 0; i < res.permissions.length; i++) {
      if (res.permissions[i] === 'ohos.permission.CAMERA' && res.authResults[i] === 0) {
        return interactiveLiveness.startLivenessDetection({
          isSilentMode: 'INTERACTIVE_MODE' as interactiveLiveness.DetectionMode,
          routeMode: 'back' as interactiveLiveness.RouteRedirectionMode,
          actionsNum: 1 as interactiveLiveness.ActionsNumber,
          speechSwitch: true
        })
      }
    }
    return false
  }

  static async getDetectionResultInfo(): Promise<interactiveLiveness.InteractiveLivenessResult> {
    let result = await interactiveLiveness.getInteractiveLivenessResult()
    return result
  }
}