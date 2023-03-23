import { Chrome } from '@dash/components';
import type { StoryFn, ComponentMeta } from '@storybook/react';

export default {
  title: 'Dashboard/Core/Chrome', // eslint-disable-line
  component: Chrome,
  parameters: { layout: `fullscreen` },
} as ComponentMeta<typeof Chrome>;

const Template: StoryFn<typeof Chrome> = (args) => (
  <Chrome {...args}>
    <h1 className="text-center">Page content here...</h1>
  </Chrome>
);

// @screenshot
export const Open = Template.bind({});
Open.args = {
  mobileSidebarOpen: true,
  onMobileHamburgerClick: () => {},
  onMobileSidebarClose: () => {},
  sidebarCollapsed: false,
  onToggleSidebarCollapsed: () => {},
  urlPath: `/`,
};

export const Closed = Template.bind({});
Closed.args = {
  ...Open.args,
  mobileSidebarOpen: false,
};

export const Collapsed = Template.bind({});
Collapsed.args = {
  ...Open.args,
  sidebarCollapsed: true,
};
