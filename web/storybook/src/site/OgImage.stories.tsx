import type { Meta } from '@storybook/react';
import SiteOgImage from './SiteOgImage';
import LockdownGuideOgImage from './LockdownGuideOgImage';
import FiveThingsYouForgotOgImage from './FiveThingsYouForgotOgImage';

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
