import { ComponentStory, ComponentMeta } from '@storybook/react';
import RadioGroup from './RadioGroup';

export default {
  title: `Dashboard/Core/RadioGroup`,
  component: RadioGroup,
} as ComponentMeta<typeof RadioGroup>;

const Template: ComponentStory<typeof RadioGroup> = (args) => <RadioGroup {...args} />;

export const Default = Template.bind({});
Default.args = {
  options: [`This way`, `That way`, `The other way`],
  selectedOption: `This way`,
};
