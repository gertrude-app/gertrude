import { BlockGroupList } from '@dash/components';
import type { Meta, StoryObj } from '@storybook/react';
import { withStatefulChrome } from '../../decorators/StatefulChrome';
import { props } from '../../story-helpers';

const meta = {
  title: 'Dashboard/iOS/Block Groups',
  component: BlockGroupList,
  parameters: { layout: `fullscreen` },
  decorators: [withStatefulChrome],
} satisfies Meta<typeof BlockGroupList>;

type Story = StoryObj<typeof meta>;

const groups = [
  {
    id: `1`,
    name: `Ads`,
    description: `Block the most common ad providers across all apps.`,
    longDescription: `Blocks the 20 most common ad providers, including Google ads, in all browsers and apps. Does not guarantee to block all ads, but should make a noticeable difference.`,
  },
  {
    id: `2`,
    name: `AI features`,
    description: `Block certain cloud-based AI features like image recognition.`,
    longDescription: `Blocks certain cloud-based AI features like image recognition. For example, the iOS 18 feature where an item in a photo can be long-pressed, identified, and searched for online.`,
  },
  {
    id: `3`,
    name: `App store images`,
    description: `Block images from the App Store.`,
    longDescription: `Eliminates all images for apps in the App Store, and in other places where the App Store appears, like in the Messages texting app.`,
  },
  {
    id: `4`,
    name: `Apple Maps images`,
    description: `Block all images from Apple Maps business listings.`,
    longDescription: `Apple Maps business listings show photos uploaded by customers and businesses, and for certain types of businesses, these can be explicit. This group blocks all images from within Apple Maps.`,
  },
  {
    id: `5`,
    name: `apple.com`,
    description: `Block web access to apple.com and linked sites.`,
    longDescription: `Certain parts of iOS (including the Settings app) contain links to the apple.com website. It is possible to view these pages and from there follow links to other parts of the web. This group blocks this access.`,
  },
  {
    id: `6`,
    name: `GIFs`,
    description: `Block GIFs in Messages #images, WhatsApp, Signal, and more.`,
    longDescription: `Blocks viewing and searching for GIFs in the #images feature of Apple's texting app, plus in other common messaging apps like WhatsApp, Skype, and Signal.`,
  },
  {
    id: `7`,
    name: `Spotlight`,
    description: `Block internet searches through Spotlight.`,
    longDescription: `The built in search bar in iOS (called Spotlight) allows searching for information and images from the internet. This group stops all spotlight internet searches. On-device data searches are not blocked.`,
  },
  {
    id: `8`,
    name: `WhatsApp`,
    description: `Block some parts of WhatsApp, including media content.`,
    longDescription: `This group attempts to block some of aspects of the WhatsApp app, including the media channels. It is experimental, and does not guarantee by any means that the app will be safe for children, but it does reduce some risks.`,
  },
  {
    id: `9`,
    name: `Spotify images`,
    description: `Block images from the Spotify app.`,
    longDescription: `Blocks images displayed in the Spotify app, including album artwork, artist photos, and playlist covers. This helps prevent exposure to potentially explicit or inappropriate imagery while still allowing music playback.`,
  },
];

export const Default: Story = props({
  groups,
  enabledGroupIds: [`1`, `2`, `3`, `5`, `6`, `7`],
  onToggle: () => {},
});

export default meta;
