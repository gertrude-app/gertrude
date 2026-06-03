import { Trash2Icon } from 'lucide-react';
import React from 'react';
import Button from '#/components/ui/Button';
import ConfirmationDialog from '#/components/ui/ConfirmationDialog';

const DestructiveExample: React.FC = () => {
  const [open, setOpen] = React.useState(false);

  return (
    <div className="grid h-full place-items-center p-8">
      <Button
        type="button"
        variant="destructive"
        icon={Trash2Icon}
        onClick={() => setOpen(true)}
      >
        Delete keychain
      </Button>
      <ConfirmationDialog
        open={open}
        onOpenChange={setOpen}
        confirmationQuestion="Delete this keychain?"
        description="This will remove the keychain from every child using it. This action cannot be undone."
        actions={[
          { text: `Cancel`, variant: `ghost` },
          {
            text: `Delete keychain`,
            variant: `destructive`,
            icon: Trash2Icon,
            onClick: () => new Promise((resolve) => window.setTimeout(resolve, 700)),
          },
        ]}
      />
    </div>
  );
};

export default DestructiveExample;
