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
  <div className="bg-gradient-to-l from-[rgb(140,140,140)] to-[rgb(230,230,236)] rounded-2xl w-[400px] h-[276px]">
    <MenuBar {...args} />
  </div>
);
export const LightMode = LightTemplate.bind({});
LightMode.args = {
  filterOn: true,
  keystrokeMonitoring: false,
  screenshotMonitoring: true,
};

const LightOverLightTemplate: ComponentStory<typeof MenuBar> = (args) => (
  <div className="bg-[rgb(230,230,236)] rounded-2xl w-[400px] h-[276px]">
    <MenuBar {...args} />
  </div>
);
export const LightModeOverLightBackground = LightOverLightTemplate.bind({});
LightModeOverLightBackground.args = {
  filterOn: true,
  keystrokeMonitoring: false,
  screenshotMonitoring: true,
};

const LightOverDarkTemplate: ComponentStory<typeof MenuBar> = (args) => (
  <div className="bg-[rgb(140,140,140)] rounded-2xl w-[400px] h-[276px]">
    <MenuBar {...args} />
  </div>
);
export const LightModeOverDarkBackground = LightOverDarkTemplate.bind({});
LightModeOverDarkBackground.args = {
  filterOn: true,
  keystrokeMonitoring: false,
  screenshotMonitoring: true,
};

const DarkTemplate: ComponentStory<typeof MenuBar> = (args) => (
  <div className="bg-gradient-to-l from-[rgb(27,27,27)] to-[rgb(120,120,120)] rounded-2xl w-[400px] h-[276px] dark">
    <MenuBar {...args} />
  </div>
);
export const DarkMode = DarkTemplate.bind({});
DarkMode.args = {
  filterOn: true,
  keystrokeMonitoring: false,
  screenshotMonitoring: true,
};

const DarkOverLightTemplate: ComponentStory<typeof MenuBar> = (args) => (
  <div className="bg-[rgb(120,120,120)] rounded-2xl w-[400px] h-[276px] dark">
    <MenuBar {...args} />
  </div>
);
export const DarkModeOverLightBackground = DarkOverLightTemplate.bind({});
DarkModeOverLightBackground.args = {
  filterOn: true,
  keystrokeMonitoring: false,
  screenshotMonitoring: true,
};

const DarkOverDarkTemplate: ComponentStory<typeof MenuBar> = (args) => (
  <div className="bg-[rgb(27,27,27)] rounded-2xl w-[400px] h-[276px] dark">
    <MenuBar {...args} />
  </div>
);
export const DarkModeOverDarkBackground = DarkOverDarkTemplate.bind({});
DarkModeOverDarkBackground.args = {
  filterOn: false,
  keystrokeMonitoring: true,
  screenshotMonitoring: true,
};
