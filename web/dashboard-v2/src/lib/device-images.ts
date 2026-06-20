const deviceImageBaseUrls = {
  mac: `/devices/macs`,
  iphone: `/devices/iphones`,
  ipad: `/devices/ipads`,
};

export const deviceImageUrl = (
  deviceType: keyof typeof deviceImageBaseUrls,
  modelIdentifier: string,
): string => `${deviceImageBaseUrls[deviceType]}/${modelIdentifier}.png`;

export const macImageUrl = (modelIdentifier: string): string =>
  deviceImageUrl(`mac`, modelIdentifier);
