import { Button, Modal, SlideOver, Textarea } from '@gertrude/ui';
import React from 'react';
import type { UnlockRequest, UnlockRequestKeyDraft } from '#/components/types';
import UnlockRequestResponsePanel from './UnlockRequestResponsePanel';

interface Props {
  request: UnlockRequest;
  keychainOptions: Array<{ id: string; name: string }>;
  onDeny: (id: string, reason: string) => void;
  onAllow: (id: string, keys: UnlockRequestKeyDraft[]) => void;
}

const UnlockRequestCard: React.FC<Props> = ({
  request,
  keychainOptions,
  onDeny,
  onAllow,
}) => {
  const [denyModalOpen, setDenyModalOpen] = React.useState(false);
  const [reviewOpen, setReviewOpen] = React.useState(false);
  const [denyReason, setDenyReason] = React.useState(``);

  const handleDenyModalOpenChange = (open: boolean): void => {
    setDenyModalOpen(open);

    if (!open) {
      setDenyReason(``);
    }
  };

  const handleDenyRequest = (): void => {
    onDeny(request.id, denyReason);
    handleDenyModalOpenChange(false);
    setReviewOpen(false);
  };

  return (
    <div className="flex flex-col gap-3 rounded-2xl border border-stone-200 bg-white p-4 shadow-md shadow-stone-300/30">
      <div className="flex flex-col gap-1.5">
        <h2 className="text-lg font-medium text-stone-900">{request.personName}</h2>
        <div className="flex flex-wrap gap-1">
          {request.domains.slice(0, 4).map((domain) => (
            <span
              key={domain}
              className="rounded-md border border-stone-200 bg-stone-50 px-1.5 py-0.5 text-xs font-medium text-stone-700"
            >
              {domain}
            </span>
          ))}
          {request.domains.length > 4 && (
            <span className="text-xs text-stone-500">
              + {request.domains.length - 4} more
            </span>
          )}
        </div>
      </div>
      {request.reason && (
        <p className="w-fit self-start rounded-2xl rounded-tl bg-stone-200 px-3.5 py-2.5 text-sm text-stone-800">
          {request.reason}
        </p>
      )}
      <div
        className="mt-auto flex justify-end gap-2"
        onClick={(event) => event.stopPropagation()}
      >
        <Button
          type="button"
          onClick={() => setDenyModalOpen(true)}
          size="small"
          variant="ghost"
        >
          Deny
        </Button>
        <Button type="button" onClick={() => setReviewOpen(true)} size="small">
          Review
        </Button>
      </div>
      <Modal
        open={denyModalOpen}
        onOpenChange={handleDenyModalOpenChange}
        title="Deny unlock request?"
        description={`${request.personName} will be told that this unlock request was denied.`}
        size="small"
        footer={
          <>
            <Button
              type="button"
              variant="ghost"
              onClick={() => handleDenyModalOpenChange(false)}
            >
              Cancel
            </Button>
            <Button type="button" variant="destructive" onClick={handleDenyRequest}>
              Deny request
            </Button>
          </>
        }
      >
        <Textarea
          value={denyReason}
          setValue={setDenyReason}
          label="Optional comment"
          placeholder="Add a reason or note for this denial..."
          rows={4}
          resize="vertical"
        />
      </Modal>
      <SlideOver
        open={reviewOpen}
        onOpenChange={setReviewOpen}
        ariaLabel={`Review ${request.personName}'s unlock request`}
        heading={`Create keys for ${request.personName}`}
        subheading="We pre-filled some sensible defaults for you, but make sure to check that everything looks good before saving!"
        size="large"
      >
        <UnlockRequestResponsePanel
          domains={request.domains}
          keychainOptions={keychainOptions}
          onDenyAll={handleDenyRequest}
          onSave={(keys) => {
            onAllow(request.id, keys);
            setReviewOpen(false);
          }}
        />
      </SlideOver>
    </div>
  );
};

export default UnlockRequestCard;
