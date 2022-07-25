import { ComponentMeta } from '@storybook/react';

import Button from './Button';

export default {
  title: `Button`,
  component: Button,
  parameters: {
    layout: `fullscreen`,
  },
} as ComponentMeta<typeof Button>;

type ButtonColor = React.ComponentProps<typeof Button>['color'];

const ButtonStory: React.FC<{ color: ButtonColor }> = ({ color }) => (
  <div className={`${bgColor(color)} p-10 space-y-5`}>
    <div className="space-y-2">
      <h2>As a button:</h2>
      <Button type="button" color={color} onClick={() => {}}>
        Join the waitlist
      </Button>
    </div>
    <div className="space-y-2">
      <h2>As a link:</h2>
      <Button type="link" color={color} to="">
        Join the waitlist
      </Button>
    </div>
    <div className="space-y-2">
      <h2>Full width:</h2>
      <Button type="button" fullWidth color={color} onClick={() => {}}>
        Join the waitlist
      </Button>
    </div>
    <div className="space-y-2">
      <h2>Small:</h2>
      <Button type="button" small color={color} onClick={() => {}}>
        Join the waitlist
      </Button>
    </div>
    <div className="space-y-2">
      <h2>Small & Full width:</h2>
      <Button type="button" fullWidth small color={color} onClick={() => {}}>
        Join the waitlist
      </Button>
    </div>
  </div>
);

export const PrimaryViolet = () => <ButtonStory color="primary-violet" />;
export const PrimaryWhite = () => <ButtonStory color="primary-white" />;
export const SecondaryWhite = () => <ButtonStory color="secondary-white" />;
export const SecondaryViolet = () => <ButtonStory color="secondary-violet" />;
export const SecondaryWarning = () => <ButtonStory color="secondary-warning" />;

function bgColor(color: ButtonColor) {
  switch (color) {
    case `primary-white`:
    case `secondary-violet`:
      return `bg-violet-500`;
    default:
      return ``;
  }
}
