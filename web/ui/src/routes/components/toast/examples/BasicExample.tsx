import React, { useState } from 'react';
import Button from '#/components/ui/Button';
import Input from '#/components/ui/Input';
import { toast } from '#/components/ui/toast';

const BasicExample: React.FC = () => {
  const [message, setMessage] = useState(`Hello from toast`);
  const text = message.trim() || `Hello from toast`;

  const runAsyncToast = (): void => {
    const shouldSucceed = Math.random() > 0.35;

    void toast
      .async(
        new Promise<string>((resolve, reject) => {
          window.setTimeout(() => {
            if (shouldSucceed) {
              resolve(text);
            } else {
              reject(new Error(text));
            }
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
    <div className="grid h-full place-items-center p-8">
      <div className="flex w-full max-w-md flex-col gap-4">
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
          <Button type="button" variant="selected" onClick={runAsyncToast}>
            Async
          </Button>
        </div>
      </div>
    </div>
  );
};

export default BasicExample;
