import { ComponentMeta } from '@storybook/react';

import Button from './Button';

export default {
  title: `Button`,
  component: Button,
} as ComponentMeta<typeof Button>;

export const PrimaryViolet = () => (
  <div className="p-20">
    <h2>As a button:</h2>
    <Button type="button" color="primary-violet" onClick={() => {}}>
      Join the waitlist
    </Button>
    <h2 className="mt-2">As a link:</h2>
    <Button type="link" color="primary-violet" to="">
      Join the waitlist
    </Button>
  </div>
);

export const PrimaryWhite = () => (
  <div className="p-20 bg-violet-500">
    <h2>As a button:</h2>
    <Button type="button" color="primary-white" onClick={() => {}}>
      Join the waitlist
    </Button>
    <h2 className="mt-2">As a link:</h2>
    <Button type="link" color="primary-white" to="">
      Join the waitlist
    </Button>
  </div>
);

export const SecondaryWhite = () => (
  <div className="p-20">
    <h2>As a button:</h2>
    <Button type="button" color="secondary-white" onClick={() => {}}>
      Join the waitlist
    </Button>
    <h2 className="mt-2">As a link:</h2>
    <Button type="link" color="secondary-white" to="">
      Join the waitlist
    </Button>
  </div>
);

export const SecondaryViolet = () => (
  <div className="p-20 bg-violet-500">
    <h2>As a button:</h2>
    <Button type="button" color="secondary-violet" onClick={() => {}}>
      Join the waitlist
    </Button>
    <h2 className="mt-2">As a link:</h2>
    <Button type="link" color="secondary-violet" to="">
      Join the waitlist
    </Button>
  </div>
);
