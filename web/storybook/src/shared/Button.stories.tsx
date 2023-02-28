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
      <Button
        type="button"
        disabled={disabled}
        color={color}
        onClick={() => {}}
        size="large"
      >
        Join the waitlist
      </Button>
    </div>
    <div className="space-y-2">
      <h2>As a link:</h2>
      <Button type="link" disabled={disabled} color={color} to="" size="large">
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
        size="large"
      >
        Join the waitlist
      </Button>
    </div>
    <div className="space-y-2">
      <h2>Medium:</h2>
      <Button
        type="button"
        disabled={disabled}
        size="medium"
        color={color}
        onClick={() => {}}
      >
        Join the waitlist
      </Button>
    </div>
    <div className="space-y-2">
      <h2>Medium & Full width:</h2>
      <Button
        type="button"
        disabled={disabled}
        fullWidth
        size="medium"
        color={color}
        onClick={() => {}}
      >
        Join the waitlist
      </Button>
    </div>
    <div className="space-y-2">
      <h2>Small</h2>
      <Button
        type="button"
        disabled={disabled}
        size="small"
        color={color}
        onClick={() => {}}
      >
        Join the waitlist
      </Button>
    </div>
    <div className="space-y-2">
      <h2>Small & Full width:</h2>
      <Button
        type="button"
        disabled={disabled}
        fullWidth
        size="small"
        color={color}
        onClick={() => {}}
      >
        Join the waitlist
      </Button>
    </div>
  </div>
);

export const PrimaryOnVioletBg = () => <ButtonStory color="primary-on-violet-bg" />;
export const SecondaryOnVioletBg = () => <ButtonStory color="secondary-on-violet-bg" />;
export const Primary = () => <ButtonStory color="primary" />;
export const Secondary = () => <ButtonStory color="secondary" />;
export const Tertiary = () => <ButtonStory color="tertiary" />;
export const Warning = () => <ButtonStory color="warning" />;
export const Disabled = () => <ButtonStory color="warning" disabled />;

function bgColor(color: ButtonColor): string {
  return color.includes(`on-violet-bg`) ? `bg-violet-500` : `bg-white`;
}
