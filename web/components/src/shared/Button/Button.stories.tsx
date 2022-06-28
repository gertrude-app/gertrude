import { ComponentStory, ComponentMeta } from '@storybook/react';

import Button from './Button';

export default {
  title: `Button`,
  component: Button,
} as ComponentMeta<typeof Button>;

const Template: ComponentStory<typeof Button> = (args) => <Button {...args} />;

export const PrimaryViolet = () => (
  <div className="p-20">
    <Button type="primary-violet" onClick={() => {}}>
      Join the waitlist
    </Button>
  </div>
);

export const PrimaryWhite = () => (
  <div className="p-20 bg-violet-500">
    <Button type="primary-white" onClick={() => {}}>
      Join the waitlist
    </Button>
  </div>
);

export const SecondaryWhite = () => (
  <div className="p-20">
    <Button type="secondary-white" onClick={() => {}}>
      Cancel
    </Button>
  </div>
);

export const SecondaryViolet = () => (
  <div className="p-20 bg-violet-500">
    <Button type="secondary-violet" onClick={() => {}}>
      Join the waitlist
    </Button>
  </div>
);
