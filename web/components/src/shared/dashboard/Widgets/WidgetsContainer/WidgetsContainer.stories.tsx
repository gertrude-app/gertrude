import { ComponentStory, ComponentMeta } from '@storybook/react';
import { withStatefulChrome } from '../../../../decorators/StatefulChrome';
import WidgetsContainer from './WidgetsContainer';

export default {
  title: `Dashboard/Dashboard/WidgetsContainer`,
  component: WidgetsContainer,
  decorators: [withStatefulChrome],
  parameters: { layout: 'fullscreen' },
} as ComponentMeta<typeof WidgetsContainer>;

const Template: ComponentStory<typeof WidgetsContainer> = (args) => (
  <WidgetsContainer {...args} />
);

export const Default = Template.bind({});
