import { StoryScreen, galleryParameters } from '@gertrude/ui/src/storybook/StoryLayout';
import type { DevicesPageData } from '#/components/devices/types';
import type { ComponentProps, ReactElement } from 'react';
import DevicesPage from './DevicesPage';

const noop = (): void => {};

const macs: DevicesPageData[`macs`] = [
  {
    id: `mac-family`,
    type: `mac`,
    name: `Family MacBook`,
    modelName: `14-inch MacBook Pro (2023)`,
    modelIdentifier: `Mac14,9`,
    macOSVersion: `26.0`,
    people: [
      { id: `person-jude`, name: `Jude` },
      { id: `person-mabel`, name: `Mabel` },
    ],
  },
  {
    id: `mac-school`,
    type: `mac`,
    modelName: `13-inch MacBook Air (2024)`,
    modelIdentifier: `Mac15,12`,
    macOSVersion: `15.6`,
    people: [{ id: `person-jude`, name: `Jude` }],
  },
];

const mobileDevices: DevicesPageData[`mobileDevices`] = [
  {
    id: `iphone-jude`,
    type: `iphone`,
    modelName: `iPhone 15 Pro`,
    modelIdentifier: `iPhone16,1`,
    iOSVersion: `18.5`,
    person: { id: `person-jude`, name: `Jude` },
    connectedApps: [`blocker`, `podcasts`, `music`],
    supervisionStatus: `complete`,
  },
  {
    id: `ipad-mabel`,
    type: `ipad`,
    modelName: `iPad Air (5th gen)`,
    modelIdentifier: `iPad13,16`,
    iOSVersion: `26.0`,
    person: { id: `person-mabel`, name: `Mabel` },
    connectedApps: [`blocker`],
    supervisionStatus: `claimed`,
  },
  {
    id: `iphone-caleb`,
    type: `iphone`,
    modelName: `iPhone 16`,
    modelIdentifier: `iPhone17,3`,
    iOSVersion: `26.0`,
    person: { id: `person-caleb`, name: `Caleb` },
    connectedApps: [],
  },
];

const defaultData: DevicesPageData = { macs, mobileDevices };

type DevicesPageProps = ComponentProps<typeof DevicesPage>;

const renderPage = (overrides: Partial<DevicesPageProps> = {}): ReactElement => (
  <StoryScreen>
    <DevicesPage
      state={{ status: `success`, data: defaultData }}
      peopleHref="/people"
      {...overrides}
    />
  </StoryScreen>
);

const meta = {
  title: 'Account/Pages/Devices',
  component: DevicesPage,
  parameters: { layout: 'fullscreen', screenshotsAt: ['mobile', 'desktop'] },
};

export default meta;

export const Default = {
  parameters: galleryParameters,
  render: () => renderPage(),
};

export const MacOnly = {
  name: 'Macs only',
  parameters: galleryParameters,
  render: () =>
    renderPage({ state: { status: `success`, data: { macs, mobileDevices: [] } } }),
};

export const MobileOnly = {
  name: 'iPhones and iPads only',
  parameters: galleryParameters,
  render: () =>
    renderPage({ state: { status: `success`, data: { macs: [], mobileDevices } } }),
};

export const SupervisionStates = {
  name: 'Supervision states',
  parameters: galleryParameters,
  render: () =>
    renderPage({
      state: {
        status: `success`,
        data: {
          macs: [],
          mobileDevices: [
            mobileDevices[0]!,
            { ...mobileDevices[1]!, supervisionStatus: `supervised` },
            {
              ...mobileDevices[1]!,
              id: `ipad-pending-claim`,
              person: { id: `person-caleb`, name: `Caleb` },
              supervisionStatus: `pendingClaim`,
            },
          ],
        },
      },
    }),
};

export const Empty = {
  parameters: galleryParameters,
  render: () =>
    renderPage({
      state: { status: `success`, data: { macs: [], mobileDevices: [] } },
    }),
};

export const Loading = {
  parameters: galleryParameters,
  render: () => renderPage({ state: { status: `loading` } }),
};

export const Error = {
  parameters: galleryParameters,
  render: () =>
    renderPage({
      state: {
        status: `error`,
        message: `Check your connection and try again.`,
        onRetry: noop,
      },
    }),
};
