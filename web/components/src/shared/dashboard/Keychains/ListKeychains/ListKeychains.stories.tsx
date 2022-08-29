import { ComponentStory, ComponentMeta } from '@storybook/react';
import { withStatefulChrome } from '../../../../decorators/StatefulChrome';
import ListKeychains from './ListKeychains';

export default {
  title: `Dashboard/Keychains/ListKeychains`,
  component: ListKeychains,
  parameters: { layout: `fullscreen` },
  decorators: [withStatefulChrome],
} as ComponentMeta<typeof ListKeychains>;

const Template: ComponentStory<typeof ListKeychains> = (args) => (
  <ListKeychains {...args} />
);

export const Default = Template.bind({});
Default.args = {
  keychains: [
    {
      id: `1`,
      isPublic: true,
      name: `HTC`,
      description: `Lorem ipsum, dolor sit amet consectetur adipisicing elit. Tempore laudantium velit assumenda nemo exercitationem.`,
      keys: 232,
    },
    {
      id: `2`,
      isPublic: true,
      name: `Jimmy's Music Theory`,
      description: `Lorem ipsum, dolor sit amet consectetur adipisicing elit. Tempore laudantium velit assumenda nemo exercitationem.`,
      keys: 7,
    },
    {
      id: `3`,
      isPublic: false,
      name: `Jason's blog`,
      description: `Lorem ipsum, dolor sit amet consectetur adipisicing elit. Tempore laudantium velit assumenda nemo exercitationem.`,
      keys: 3,
    },
    {
      id: `4`,
      isPublic: true,
      name: `Misc McStandardishlong Keys`,
      description: `Lorem ipsum, dolor sit amet consectetur adipisicing elit. Tempore laudantium velit assumenda nemo exercitationem.`,
      keys: 433,
    },
    {
      id: `5`,
      isPublic: false,
      name: `John's stuff`,
      description: `Lorem ipsum, dolor sit amet consectetur adipisicing elit. Tempore laudantium velit assumenda nemo exercitationem.`,
      keys: 674,
    },
    {
      id: `6`,
      isPublic: true,
      name: `Smith Family`,
      description: `Lorem ipsum, dolor sit amet consectetur adipisicing elit. Tempore laudantium velit assumenda nemo exercitationem.`,
      keys: 112,
    },
    {
      id: `7`,
      isPublic: true,
      name: `Meyer Hatchery`,
      description: `Lorem ipsum, dolor sit amet consectetur adipisicing elit. Tempore laudantium velit assumenda nemo exercitationem.`,
      keys: 14,
    },
    {
      id: `8`,
      isPublic: false,
      name: `Facebook`,
      description: `Lorem ipsum, dolor sit amet consectetur adipisicing elit. Tempore laudantium velit assumenda nemo exercitationem.`,
      keys: 2390,
    },
    {
      id: `9`,
      isPublic: false,
      name: `Friends Library`,
      description: `Lorem ipsum, dolor sit amet consectetur adipisicing elit. Tempore laudantium velit assumenda nemo exercitationem.`,
      keys: 2,
    },
  ],
};
