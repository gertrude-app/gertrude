import type { ComponentMeta } from '@storybook/react';
import * as ProductHunt from './ProductHunt';

export default {
  title: 'Site/Product Hunt', // eslint-disable-line
  component: ProductHunt.BlockedRequests,
  parameters: {
    layout: `fullscreen`,
    viewport: {
      viewports: {
        productHunt: {
          name: `ProductHunt`,
          styles: {
            width: `1270px`,
            height: `760px`,
          },
        },
      },
      defaultViewport: `productHunt`,
    },
  },
} as ComponentMeta<typeof ProductHunt.BlockedRequests>;

export const Image1 = () => <ProductHunt.BlockedRequests />;
export const Image2 = () => <ProductHunt.UnlockRequest />;
export const Image3 = () => <ProductHunt.ProtectFamily />;
