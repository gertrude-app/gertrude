import type { Meta } from '@storybook/react';
import SiteOgImage from './og-images/SiteOgImage';
import LockdownGuideOgImage from './og-images/LockdownGuideOgImage';
import FiveThingsYouForgotOgImage from './og-images/FiveThingsYouForgotOgImage';
import GifAppMessagesOgImage from './og-images/GifAppInMessagesOgImage';

export default {
  title: 'Site/OgImages', // eslint-disable-line
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
export const FiveThingsYouForgot = () => <FiveThingsYouForgotOgImage />;
export const GifAppMessages = () => <GifAppMessagesOgImage />;
