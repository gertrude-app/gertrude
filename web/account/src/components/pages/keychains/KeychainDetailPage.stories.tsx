import { StoryScreen, galleryParameters } from '@gertrude/ui/src/storybook/StoryLayout';
import type { KeychainDetail } from '#/components/types';
import KeychainDetailPage from './KeychainDetailPage';

const keychain = {
  id: `school-keychain`,
  name: `School and creative projects`,
  description: `Websites and app connections used for classes, research, and creative work.`,
  warning: `This keychain allows searching for images within Google Docs. It is possible to find images that are mildly or moderately sexual or inappropriate in the image search. Please familiarize yourself with the image search and weigh the risk before using this keychain.`,
  isPublic: true,
  keys: [
    {
      id: `subdomain-key`,
      key: {
        type: `anySubdomain`,
        domain: `khanacademy.org`,
        scope: { type: `webBrowsers` },
      },
      comment: `Main site, exercises, videos, and supporting resources`,
      expiration: `2027-09-14T20:30:00.000Z`,
    },
    {
      id: `domain-key`,
      key: {
        type: `domain`,
        domain: `api.minecraftservices.com`,
        scope: {
          type: `single`,
          single: { type: `identifiedAppSlug`, identifiedAppSlug: `minecraft` },
        },
      },
      appName: `Minecraft`,
    },
    {
      id: `regex-key`,
      key: {
        type: `domainRegex`,
        pattern: `^p\\d+-contacts\\.icloud\\.com$`,
        scope: { type: `unrestricted` },
      },
    },
    {
      id: `ip-key`,
      key: {
        type: `ipAddress`,
        ipAddress: `fe80::1ca8:ae3f:8128:c90b%en0`,
        scope: {
          type: `single`,
          single: { type: `bundleId`, bundleId: `com.example.unknown-helper` },
        },
      },
      comment: `Local classroom device`,
    },
    {
      id: `path-key`,
      key: {
        type: `path`,
        path: `accounts.google.com/o/oauth2`,
        scope: {
          type: `single`,
          single: { type: `identifiedAppSlug`, identifiedAppSlug: `safari` },
        },
      },
      appName: `Safari`,
      expiration: `2025-01-10T14:00:00.000Z`,
    },
    {
      id: `skeleton-key`,
      key: {
        type: `skeleton`,
        scope: { type: `identifiedAppSlug`, identifiedAppSlug: `spotify` },
      },
      appName: `Spotify`,
    },
    {
      id: `strict-browser-key`,
      key: {
        type: `domain`,
        domain: `docs.google.com`,
        scope: { type: `webBrowsers` },
      },
    },
    {
      id: `unknown-skeleton-key`,
      key: {
        type: `skeleton`,
        scope: { type: `bundleId`, bundleId: `(no bundle id)` },
      },
      comment: `Historical app key with an unknown application`,
    },
  ],
} satisfies KeychainDetail;

const meta = {
  title: 'Account/Pages/Keychain Detail',
  component: KeychainDetailPage,
  parameters: { layout: 'fullscreen', screenshotsAt: ['mobile', 'desktop'] },
};

export default meta;

export const Default = {
  parameters: galleryParameters,
  render: () => (
    <StoryScreen>
      <KeychainDetailPage state={{ status: `success`, data: keychain }} />
    </StoryScreen>
  ),
};

export const Empty = {
  parameters: galleryParameters,
  render: () => (
    <StoryScreen>
      <KeychainDetailPage
        state={{
          status: `success`,
          data: {
            id: `empty-keychain`,
            name: `New keychain`,
            description: `Ready for keys when you need them.`,
            isPublic: false,
            keys: [],
          },
        }}
      />
    </StoryScreen>
  ),
};

export const Loading = {
  parameters: galleryParameters,
  render: () => (
    <StoryScreen>
      <KeychainDetailPage state={{ status: `loading` }} />
    </StoryScreen>
  ),
};

export const Error = {
  parameters: galleryParameters,
  render: () => (
    <StoryScreen>
      <KeychainDetailPage
        state={{
          status: `error`,
          message: `This keychain may have been deleted or belong to another account.`,
          onRetry: () => {},
        }}
      />
    </StoryScreen>
  ),
};
