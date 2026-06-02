import React from 'react';
import Button from '#/components/ui/Button';
import Modal from '#/components/ui/Modal';

const BasicExample: React.FC = () => {
  const [open, setOpen] = React.useState(false);

  return (
    <div className="grid h-full place-items-center p-8">
      <Button type="button" variant="primary" onClick={() => setOpen(true)}>
        Open modal
      </Button>
      <Modal
        open={open}
        onOpenChange={setOpen}
        title="Grant custom duration"
        description="Sally requested a 15 minute filter suspension. Choose a different duration before granting."
        footer={
          <>
            <Button type="button" variant="ghost" onClick={() => setOpen(false)}>
              Cancel
            </Button>
            <Button type="button" variant="primary" onClick={() => setOpen(false)}>
              Grant 45 minutes
            </Button>
          </>
        }
      >
        <div className="grid gap-3">
          <label className="grid gap-1.5 text-sm font-medium text-stone-900">
            Duration
            <div className="flex items-center gap-2">
              <input
                value="45"
                readOnly
                className="w-24 rounded-lg border border-stone-300 bg-white px-2.5 py-1.5 text-stone-900 shadow-sm outline-none"
              />
              <span className="text-sm text-stone-600">minutes</span>
            </div>
          </label>
          <p className="text-sm leading-6 text-stone-600">
            This is placeholder form content for the modal body.
          </p>
        </div>
      </Modal>
    </div>
  );
};

export default BasicExample;
