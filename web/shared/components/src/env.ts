export function isCypress(): boolean {
  return typeof window !== `undefined` && `Cypress` in window;
}

export function isScreenshotTest(): boolean {
  // @ts-ignore
  return import.meta.env?.STORYBOOK_SCREENSHOT_TESTING !== undefined;
}
