import '../../account/src/styles.css';
import type { Preview } from '@storybook/tanstack-react';

const preview: Preview = {
  parameters: {
    controls: {
      matchers: {
        color: /(background|color)$/i,
        date: /Date$/i,
      },
    },
    screenshotViewports: {
      mobile: { width: 390, height: 844 },
      medium: { width: 600, height: 900 },
      tablet: { width: 768, height: 1024 },
      desktop: { width: 1440, height: 900 },
    },
  },
};

export default preview;
