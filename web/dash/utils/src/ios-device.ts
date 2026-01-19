export type IOSDeviceType = `iPhone` | `iPad`;

export function iosDeviceType(modelName: string): IOSDeviceType {
  return modelName.toLowerCase().includes(`ipad`) ? `iPad` : `iPhone`;
}
