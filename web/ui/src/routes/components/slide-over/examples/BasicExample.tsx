import React from 'react';
import Button from '#/components/ui/Button';
import SlideOver from '#/components/ui/SlideOver';

const BasicExample: React.FC = () => {
  const [open, setOpen] = React.useState(false);

  return (
    <div className="grid h-full place-items-center p-8">
      <Button type="button" variant="primary" onClick={() => setOpen(true)}>
        Open slide over
      </Button>
      <SlideOver open={open} onOpenChange={setOpen} ariaLabel="Example slide over">
        <div className="flex h-full w-full flex-col gap-4 p-6">
          <p className="text-sm leading-6 text-stone-600">
            Put any custom content inside the slide over.
          </p>
          <Button type="button" onClick={() => setOpen(false)}>
            Close
          </Button>
        </div>
      </SlideOver>
    </div>
  );
};

export default BasicExample;
