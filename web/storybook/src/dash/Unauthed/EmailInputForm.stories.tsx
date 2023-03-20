import { EmailInputForm } from '@dash/components';
import type { StoryFn, ComponentMeta } from '@storybook/react';

export default {
  title: 'Dashboard/Unauthed/EmailInputForm', // eslint-disable-line
  component: EmailInputForm,
  parameters: { layout: `centered` },
} as ComponentMeta<typeof EmailInputForm>;

const Template: StoryFn<typeof EmailInputForm> = (args) => (
  <div className="max-w-md">
    <EmailInputForm {...args} />
  </div>
);

export const Default = Template.bind({});
Default.args = {
  title: `Join the waitlist`,
  subTitle: `We'll notify you when you can begin trying out Gertrude`,
};
