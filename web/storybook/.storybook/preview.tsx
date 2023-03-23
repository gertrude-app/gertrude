import './index.css';
import { MemoryRouter } from 'react-router-dom';

export const decorators = [
  (Story) => (
    <MemoryRouter>
      <Story />
    </MemoryRouter>
  ),
];

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
  options: { showPanel: false },
  actions: { argTypesRegex: '^on[A-Z].*' },
  viewport: { viewports },
  controls: {
    matchers: {
      color: /(background|color)$/i,
      date: /Date$/,
    },
  },
};
