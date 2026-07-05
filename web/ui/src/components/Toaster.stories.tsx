import React from 'react';
import type { Meta, StoryObj } from '@storybook/tanstack-react';
import Button from './Button';
import Input from './Input';
import Toaster from './Toaster';
import { toast } from '#/lib/toast';
import { StoryCanvas, StorySection, galleryParameters } from '#/storybook/StoryLayout';

const ToastControls: React.FC = () => {
  const [message, setMessage] = React.useState(`Hello from toast`);
  const text = message.trim() || `Hello from toast`;

  const runAsyncToast = (shouldSucceed: boolean): void => {
    void toast
      .async(
        new Promise<string>((resolve, reject) => {
          window.setTimeout(() => {
            if (shouldSucceed) {
              resolve(text);
              return;
            }

            reject(new Error(text));
          }, 1600);
        }),
        {
          loading: `Working on ${text}`,
          success: `Finished ${text}`,
          error: `Could not finish ${text}`,
        },
      )
      .catch(() => undefined);
  };

  return (
    <div className="flex w-full max-w-md flex-col gap-4 rounded-2xl border border-stone-200 bg-white p-5 shadow-sm shadow-stone-300/30">
      <Input type="text" label="Toast message" value={message} setValue={setMessage} />
      <div className="flex flex-wrap gap-2">
        <Button type="button" variant="primary" onClick={() => toast.success(text)}>
          Success
        </Button>
        <Button type="button" variant="destructive" onClick={() => toast.error(text)}>
          Error
        </Button>
        <Button type="button" onClick={() => toast.info(text)}>
          Info
        </Button>
        <Button type="button" variant="selected" onClick={() => runAsyncToast(true)}>
          Async success
        </Button>
        <Button type="button" variant="selected" onClick={() => runAsyncToast(false)}>
          Async error
        </Button>
        <Button type="button" variant="ghost" onClick={() => toast.dismiss()}>
          Dismiss all
        </Button>
      </div>
    </div>
  );
};

const meta = {
  title: 'UI/Components/Toaster',
  component: Toaster,
  args: {},
  argTypes: {},
  parameters: { layout: `fullscreen` },
} satisfies Meta<typeof Toaster>;

export default meta;

type Story = StoryObj<typeof meta>;

export const Variants: Story = {
  parameters: galleryParameters,
  render: () => (
    <StoryCanvas innerClassName="max-w-3xl">
      <StorySection title="Toast controls" contentClassName="block">
        <ToastControls />
      </StorySection>
      <Toaster />
    </StoryCanvas>
  ),
};
