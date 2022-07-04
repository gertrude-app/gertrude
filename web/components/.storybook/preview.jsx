import './index.css';
import { addDecorator } from '@storybook/react';
import { MemoryRouter } from 'react-router-dom';

addDecorator((storyFn) => <MemoryRouter>{storyFn()}</MemoryRouter>);

const viewports = {
  smallMobile: {
    name: 'Small mobile',
    styles: {
      width: '375px',
      height: '812px',
    },
  },
  largeMobile: {
    name: 'Large mobile',
    styles: {
      width: '428px',
      height: '926px',
    },
  },
};

export const parameters = {
  actions: { argTypesRegex: '^on[A-Z].*' },
  viewport: { viewports },
  controls: {
    matchers: {
      color: /(background|color)$/i,
      date: /Date$/,
    },
  },
};
