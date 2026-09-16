import type { ConnectedIOSApp } from '#/components/devices/types';

export interface IosSettingsSearch {
  section?: ConnectedIOSApp;
}

const connectedIOSApps: ConnectedIOSApp[] = [`blocker`, `podcasts`, `music`];

export const validateIosSettingsSearch = (
  search: Record<string, unknown>,
): IosSettingsSearch => ({
  section:
    typeof search[`section`] === `string` &&
    connectedIOSApps.includes(search[`section`] as ConnectedIOSApp)
      ? (search[`section`] as ConnectedIOSApp)
      : undefined,
});
