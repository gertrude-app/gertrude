import { EmailInputForm } from '@dash/components';
import type { Meta, StoryObj } from '@storybook/react';
import { props } from '../../story-helpers';

const meta = {
  title: 'Dashboard/Unauthed/EmailInputForm', // eslint-disable-line
  component: EmailInputForm,
  parameters: { layout: `centered` },
  decorators: [(story) => <div className="max-w-md">{story()}</div>],
} satisfies Meta<typeof EmailInputForm>;

type Story = StoryObj<typeof meta>;

export const Default: Story = props({
  title: `Join the waitlist`,
  subTitle: `We'll notify you when you can begin trying out Gertrude`,
  email: ``,
  setEmail: () => {},
  setPassword: () => {},
  onSubmit: () => {},
});

export default meta;
