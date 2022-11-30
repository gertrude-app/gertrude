import { OgImage } from '@site/components';
import type { ComponentStory, ComponentMeta } from '@storybook/react';

export default {
  title: 'Site/OgImage', // eslint-disable-line
  component: OgImage,
  parameters: {
    layout: `fullscreen`,
    viewport: {
      viewports: {
        ogImage: {
          name: `OgImage`,
          styles: {
            width: `1200px`,
            height: `627px`,
          },
        },
      },
      defaultViewport: `ogImage`,
    },
  },
} as ComponentMeta<typeof OgImage>;

const Template: ComponentStory<typeof OgImage> = (args) => <OgImage {...args} />;

export const Default = Template.bind({});
