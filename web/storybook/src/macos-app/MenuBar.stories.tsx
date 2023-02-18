import type { ComponentStory, ComponentMeta } from '@storybook/react';
import MenuBar from '../../../appviews/src/MenuBar/MenuBar';

export default {
  title: 'MacOSApp/MenuBar', // eslint-disable-line
  component: MenuBar,
  parameters: {
    layout: `centered`,
  },
} as ComponentMeta<typeof MenuBar>;

const LightTemplate: ComponentStory<typeof MenuBar> = (args) => (
  <div className="bg-[rgb(220,220,220)] rounded-lg">
    <MenuBar {...args} />
  </div>
);

export const Default = LightTemplate.bind({});
