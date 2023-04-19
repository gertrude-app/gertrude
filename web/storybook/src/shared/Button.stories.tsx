import { Button } from '@shared/components';
import type { StoryObj, Meta } from '@storybook/react';

const meta = {
  title: 'Shared/Button', // eslint-disable-line
  component: Button,
  parameters: { layout: `fullscreen` },
} satisfies Meta<typeof Button>;

type Story = StoryObj<typeof Button>;

export const Primary: Story = { render: () => <ButtonStory color="primary" /> };
export const Secondary: Story = { render: () => <ButtonStory color="secondary" /> };
export const Tertiary: Story = { render: () => <ButtonStory color="tertiary" /> };
export const Warning: Story = { render: () => <ButtonStory color="warning" /> };
export const Disabled: Story = { render: () => <ButtonStory color="warning" disabled /> };
export const PrimaryOnVioletBg: Story = {
  render: () => <ButtonStory color="primary-on-violet-bg" />,
};
export const SecondaryOnVioletBg: Story = {
  render: () => <ButtonStory color="secondary-on-violet-bg" />,
};

// helpers

type ButtonColor = React.ComponentProps<typeof Button>['color'];

function bgColor(color: ButtonColor): string {
  return color.includes(`on-violet-bg`) ? `bg-violet-500` : `bg-white`;
}

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

export default meta;
