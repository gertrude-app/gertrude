import { ComponentStory, ComponentMeta } from '@storybook/react';
import { Chrome } from '@dash/components';

export default {
  title: `Dashboard/Core/Chrome`,
  component: Chrome,
  parameters: { layout: `fullscreen` },
} as ComponentMeta<typeof Chrome>;

const Template: ComponentStory<typeof Chrome> = (args) => (
  <Chrome {...args}>
    <h1 className="text-center">Page content here...</h1>
  </Chrome>
);

export const Open = Template.bind({});
Open.args = {
  mobileSidebarOpen: true,
  onMobileHamburgerClick: () => {},
  onMobileSidebarClose: () => {},
  onLogout: () => alert(`you're logged out!`),
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
