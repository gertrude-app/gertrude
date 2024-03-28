import './index.css';
import React from 'react';
import { MemoryRouter } from 'react-router-dom';
import type { Preview, Decorator } from '@storybook/react';

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
