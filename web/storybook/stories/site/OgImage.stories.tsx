import type { Meta } from '@storybook/react';
import FiveThingsOgImage from './og-images/FiveThingsOgImage';
import GifAppMessagesOgImage from './og-images/GifAppInMessagesOgImage';
import LockdownGuideOgImage from './og-images/LockdownGuideOgImage';
import SiteOgImage from './og-images/SiteOgImage';
import WickedProjectOgImage from './og-images/WickedProjectOgImage';

export default {
  title: 'Site/OgImages',
  component: SiteOgImage,
  parameters: {
    layout: `fullscreen`,
    viewport: {
      viewports: {
        ogImage: {
          name: `OgImage`,
          styles: {
            width: `1200px`,
            height: `627px`,
          },
        },
      },
      defaultViewport: `ogImage`,
    },
  },
} satisfies Meta<typeof SiteOgImage>;

export const Site = () => <SiteOgImage />;
export const LockdownGuide = () => <LockdownGuideOgImage />;
export const FiveThings = () => <FiveThingsOgImage />;
export const GifAppMessages = () => <GifAppMessagesOgImage />;
export const WickedProject = () => <WickedProjectOgImage />;
