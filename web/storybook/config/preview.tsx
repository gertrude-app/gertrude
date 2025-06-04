import './index.css';
import '../../dash/app/src/css/SidebarNav.css';
import '../../dash/app/src/css/AddKeychainDrawer.css';
import React from 'react';
import { MemoryRouter } from 'react-router-dom';
import type { Decorator, Preview } from '@storybook/react';

export const decorators: [Decorator] = [
  (Story: React.FC): JSX.Element => (
    <MemoryRouter>
      <Story />
    </MemoryRouter>
  ),
];

const preview: Preview = {
  parameters: {
    controls: {
      matchers: {
        color: /(background|color)$/i,
        date: /Date$/i,
      },
    },
  },
};

export default preview;
