import React from 'react';
import type { Meta, StoryObj } from '@storybook/tanstack-react';
import Button from './Button';
import Input from './Input';
import Modal from './Modal';
import { StoryCanvas, StorySection, galleryParameters } from '#/storybook/StoryLayout';

const sizes = [`small`, `medium`, `large`] as const;

const ModalContent: React.FC = () => {
  const [duration, setDuration] = React.useState(`45`);

  return (
    <div className="grid gap-3">
      <Input
        type="number"
        label="Duration"
        value={duration}
        setValue={setDuration}
        suffix="minutes"
      />
      <p className="text-sm leading-6 text-stone-600">
        This is placeholder form content for the modal body.
      </p>
    </div>
  );
};

const meta = {
  title: 'UI/Components/Modal',
  component: Modal,
  args: {
    title: `Grant custom duration`,
    description: `Sally requested a 15 minute filter suspension. Choose a different duration before granting.`,
  },
  parameters: { layout: `fullscreen` },
} satisfies Meta<typeof Modal>;

export default meta;

type Story = StoryObj<typeof meta>;

export const Sizes: Story = {
  parameters: galleryParameters,
  render: () => (
    <StoryCanvas>
      <StorySection title="Sizes">
        {sizes.map((size) => (
          <ModalTriggerButton key={size} size={size} title={`${size} modal`} />
        ))}
      </StorySection>
    </StoryCanvas>
  ),
};

type ModalTriggerButtonProps = {
  size: (typeof sizes)[number];
  title: string;
};

const ModalTriggerButton: React.FC<ModalTriggerButtonProps> = ({ size, title }) => {
  const [open, setOpen] = React.useState(false);

  return (
    <>
      <Button type="button" onClick={() => setOpen(true)}>
        Open {size}
      </Button>
      <Modal
        open={open}
        onOpenChange={setOpen}
        size={size}
        title={title}
        description="The same component switches from dialog to drawer automatically on narrow screens."
        footer={
          <Button type="button" variant="primary" onClick={() => setOpen(false)}>
            Done
          </Button>
        }
      >
        <ModalContent />
      </Modal>
    </>
  );
};
