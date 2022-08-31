import { ComponentStory, ComponentMeta } from '@storybook/react';
import EmailInputForm from './EmailInputForm';

export default {
  title: `Dashboard/Unauthed/EmailInputForm`,
  component: EmailInputForm,
  parameters: { layout: `centered` },
} as ComponentMeta<typeof EmailInputForm>;

const Template: ComponentStory<typeof EmailInputForm> = (args) => (
  <div className="max-w-md">
    <EmailInputForm {...args} />
  </div>
);

export const Default = Template.bind({});
Default.args = {
  title: `Join the waitlist`,
  subTitle: `We'll notify you when you can begin trying out Gertrude`,
};
