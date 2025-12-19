import { Chrome } from '@dash/components';
import type { Meta, StoryObj } from '@storybook/react';
import { props } from '../story-helpers';

const meta = {
  title: 'Dashboard/Core/Chrome', // eslint-disable-line
  component: Chrome,
  parameters: { layout: `fullscreen` },
} satisfies Meta<typeof Chrome>;

type Story = StoryObj<typeof meta>;

// @screenshot
export const Open: Story = props({
  mobileSidebarOpen: true,
  onMobileHamburgerClick: () => {},
  onMobileSidebarClose: () => {},
  sidebarCollapsed: false,
  onToggleSidebarCollapsed: () => {},
  onInternalLinkClick: () => {},
  urlPath: `/`,
  children: <h1 className="text-center">Page content here...</h1>,
});

export const Closed: Story = props({
  ...Open.args,
  mobileSidebarOpen: false,
});

export const Collapsed: Story = props({
  ...Open.args,
  sidebarCollapsed: true,
});

export default meta;
