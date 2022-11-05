import { ComponentStory, ComponentMeta } from '@storybook/react';
import DmgBackground from './DmgBackground';

export default {
  title: `MacOSApp/DmgBackground`,
  component: DmgBackground,
  parameters: {
    layout: `fullscreen`,
    viewport: {
      viewports: {
        dmgWindow: {
          name: `DmgWindow`,
          styles: {
            width: `640px`,
            height: `502px`,
          },
        },
      },
      defaultViewport: `dmgWindow`,
    },
  },
} as ComponentMeta<typeof DmgBackground>;

const Template: ComponentStory<typeof DmgBackground> = (args) => (
  <DmgBackground {...args} />
);

export const Default = Template.bind({});
