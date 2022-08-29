import { ComponentStory, ComponentMeta } from '@storybook/react';
import KeyTypeOption from './KeyTypeOption';

export default {
  title: `KeyTypeOption`,
  component: KeyTypeOption,
} as ComponentMeta<typeof KeyTypeOption>;

const Template: ComponentStory<typeof KeyTypeOption> = (args) => (
  <KeyTypeOption {...args} />
);

export const Default = Template.bind({});
