import { Button } from '@shared/components';
import type { ComponentMeta } from '@storybook/react';

export default {
  title: 'Shared/Button', // eslint-disable-line
  component: Button,
  parameters: {
    layout: `fullscreen`,
  },
} as ComponentMeta<typeof Button>;

type ButtonColor = React.ComponentProps<typeof Button>['color'];

const ButtonStory: React.FC<{ color: ButtonColor; disabled?: boolean }> = ({
  color,
  disabled = false,
}) => (
  <div className={`${bgColor(color)} p-10 space-y-5`}>
    <div className="space-y-2">
      <h2>As a button:</h2>
      <Button type="button" disabled={disabled} color={color} onClick={() => {}}>
        Join the waitlist
      </Button>
    </div>
    <div className="space-y-2">
      <h2>As a link:</h2>
      <Button type="link" disabled={disabled} color={color} to="">
        Join the waitlist
      </Button>
    </div>
    <div className="space-y-2">
      <h2>Full width:</h2>
      <Button
        type="button"
        disabled={disabled}
        fullWidth
        color={color}
        onClick={() => {}}
      >
        Join the waitlist
      </Button>
    </div>
    <div className="space-y-2">
      <h2>Small:</h2>
      <Button type="button" disabled={disabled} small color={color} onClick={() => {}}>
        Join the waitlist
      </Button>
    </div>
    <div className="space-y-2">
      <h2>Small & Full width:</h2>
      <Button
        type="button"
        disabled={disabled}
        fullWidth
        small
        color={color}
        onClick={() => {}}
      >
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
export const Disabled = () => <ButtonStory color="secondary-warning" disabled />;

function bgColor(color: ButtonColor) {
  switch (color) {
    case `primary-white`:
    case `secondary-violet`:
      return `bg-violet-500`;
    default:
      return ``;
  }
}
