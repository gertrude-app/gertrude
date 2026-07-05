import { CheckIcon, Trash2Icon } from 'lucide-react';
import React from 'react';
import { fn } from 'storybook/test';
import type { Meta, StoryObj } from '@storybook/tanstack-react';
import Button from './Button';
import ConfirmationDialog from './ConfirmationDialog';
import { StoryCanvas, StorySection, galleryParameters } from '#/storybook/StoryLayout';

const confirmAction = fn();
const wait = (): Promise<void> =>
  new Promise((resolve) => window.setTimeout(resolve, 800));

const meta = {
  title: 'UI/Components/ConfirmationDialog',
  component: ConfirmationDialog,
  args: {
    confirmationQuestion: `Grant this suspension request?`,
    description: `Sally will be notified that the filter is suspended for 15 minutes. Monitoring will continue during the suspension.`,
    actions: [
      { text: `Cancel`, variant: `ghost` },
      {
        text: `Grant 15 minutes`,
        variant: `primary`,
        icon: CheckIcon,
        onClick: confirmAction,
      },
    ],
  },
  parameters: { layout: `fullscreen` },
} satisfies Meta<typeof ConfirmationDialog>;

export default meta;

type Story = StoryObj<typeof meta>;

export const Basic: Story = {
  parameters: galleryParameters,
  render: () => (
    <StoryCanvas>
      <StorySection title="Confirmations">
        <ConfirmationTrigger
          buttonText="Grant request"
          buttonVariant="primary"
          confirmationQuestion="Grant this suspension request?"
          description="Sally will be notified that the filter is suspended for 15 minutes. Monitoring will continue during the suspension."
          actions={[
            { text: `Cancel`, variant: `ghost` },
            {
              text: `Grant 15 minutes`,
              variant: `primary`,
              icon: CheckIcon,
              onClick: confirmAction,
            },
          ]}
        />
        <ConfirmationTrigger
          buttonText="Delete keychain"
          buttonVariant="destructive"
          buttonIcon={Trash2Icon}
          confirmationQuestion="Delete this keychain?"
          description="This will remove the keychain from every child using it. This action cannot be undone."
          actions={[
            { text: `Cancel`, variant: `ghost` },
            {
              text: `Delete keychain`,
              variant: `destructive`,
              icon: Trash2Icon,
              onClick: wait,
            },
          ]}
        />
      </StorySection>
    </StoryCanvas>
  ),
};

export const ActionStates: Story = {
  parameters: galleryParameters,
  render: () => (
    <StoryCanvas>
      <StorySection title="Action states">
        <ConfirmationTrigger
          buttonText="Async action"
          confirmationQuestion="Run a slower action?"
          description="The primary action shows a loading state while the promise resolves."
          actions={[
            { text: `Cancel`, variant: `ghost` },
            { text: `Run action`, variant: `primary`, onClick: wait },
          ]}
        />
        <ConfirmationTrigger
          buttonText="Disabled action"
          confirmationQuestion="Review disabled action?"
          description="Disabled actions are visible but unavailable."
          actions={[
            { text: `Cancel`, variant: `ghost` },
            { text: `Unavailable`, variant: `primary`, disabled: true },
          ]}
        />
        <ConfirmationTrigger
          buttonText="Already loading"
          confirmationQuestion="Action already in progress?"
          actions={[
            { text: `Cancel`, variant: `ghost`, disabled: true },
            { text: `Saving`, variant: `primary`, loading: true },
          ]}
        />
      </StorySection>
    </StoryCanvas>
  ),
};

type ConfirmationTriggerProps = React.ComponentProps<typeof ConfirmationDialog> & {
  buttonText: string;
  buttonVariant?: React.ComponentProps<typeof Button>[`variant`];
  buttonIcon?: React.ComponentProps<typeof Button>[`icon`];
};

const ConfirmationTrigger: React.FC<ConfirmationTriggerProps> = ({
  buttonText,
  buttonVariant,
  buttonIcon,
  ...dialogProps
}) => {
  const [open, setOpen] = React.useState(false);

  return (
    <>
      <Button
        type="button"
        variant={buttonVariant}
        icon={buttonIcon}
        onClick={() => setOpen(true)}
      >
        {buttonText}
      </Button>
      <ConfirmationDialog {...dialogProps} open={open} onOpenChange={setOpen} />
    </>
  );
};
