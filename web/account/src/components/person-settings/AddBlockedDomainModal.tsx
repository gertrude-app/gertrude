import { Button, Input, Modal } from '@gertrude/ui';
import React from 'react';

type Props = {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  onAdd: (domain: string) => void;
  initialDomain?: string;
};

const AddBlockedDomainModal: React.FC<Props> = ({
  open,
  onOpenChange,
  onAdd,
  initialDomain,
}) => {
  const formId = React.useId();
  const [domain, setDomain] = React.useState(initialDomain ?? ``);
  const trimmedDomain = domain.trim();
  const editing = initialDomain !== undefined;

  React.useEffect(() => {
    if (open) {
      setDomain(initialDomain ?? ``);
    }
  }, [initialDomain, open]);

  const handleOpenChange = (nextOpen: boolean): void => {
    onOpenChange(nextOpen);

    if (!nextOpen) {
      setDomain(``);
    }
  };

  const handleSubmit = (event: React.FormEvent<HTMLFormElement>): void => {
    event.preventDefault();
    event.stopPropagation();

    if (!trimmedDomain) {
      return;
    }

    onAdd(trimmedDomain);
    handleOpenChange(false);
  };

  return (
    <Modal
      open={open}
      onOpenChange={handleOpenChange}
      title={editing ? `Edit blocked domain` : `Add blocked domain`}
      description="This domain will be blocked at all times, even when the filter is suspended."
      size="small"
      footer={
        <>
          <Button type="button" variant="ghost" onClick={() => handleOpenChange(false)}>
            Cancel
          </Button>
          <Button type="submit" form={formId} variant="primary" disabled={!trimmedDomain}>
            {editing ? `Save Domain` : `Add Domain`}
          </Button>
        </>
      }
    >
      <form id={formId} onSubmit={handleSubmit}>
        <Input
          label="Domain"
          type="text"
          value={domain}
          setValue={setDomain}
          placeholder="example.com"
          autoComplete="off"
        />
      </form>
    </Modal>
  );
};

export default AddBlockedDomainModal;
