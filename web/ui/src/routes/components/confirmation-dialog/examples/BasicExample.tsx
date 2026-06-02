import React from 'react';
import Button from '#/components/ui/Button';
import ConfirmationDialog from '#/components/ui/ConfirmationDialog';

const BasicExample: React.FC = () => {
  const [open, setOpen] = React.useState(false);

  return (
    <div className="grid h-full place-items-center p-8">
      <Button type="button" variant="primary" onClick={() => setOpen(true)}>
        Grant request
      </Button>
      <ConfirmationDialog
        open={open}
        onOpenChange={setOpen}
        confirmationQuestion="Grant this suspension request?"
        description="Sally will be notified that the filter is suspended for 15 minutes. Monitoring will continue during the suspension."
        actions={[
          { text: 'Cancel', variant: 'ghost' },
          { text: 'Grant 15 minutes', variant: 'primary', onClick: () => undefined },
        ]}
      />
    </div>
  );
};

export default BasicExample;
