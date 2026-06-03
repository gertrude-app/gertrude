import React, { useState } from 'react';
import cx from 'clsx';
import { Badge, Button, Modal, SlideOver, Textarea } from '@gertrude/ui';
import { defaultKeyFromDomain, type UnlockRequest } from '#/lib/mock-data';
import { BanIcon, KeyIcon } from 'lucide-react';

interface Props {
  request: UnlockRequest;
}

const UnlockRequestCard: React.FC<Props> = ({ request }) => {
  const [denyModalOpen, setDenyModalOpen] = useState(false);
  const [denyReason, setDenyReason] = useState('');
  const [reviewOpen, setReviewOpen] = useState(false);
  const [currentKeyIndex, setCurrentKeyIndex] = useState(0);
  const [allowStatuses, setAllowStatuses] = useState<
    Array<'unlocked' | 'denied' | 'pending'>
  >(Array(request.domains.length).fill('pending'));
  const [keys, setKeys] = useState(request.domains.map((d) => defaultKeyFromDomain(d)));

  const handleDenyModalOpenChange = (open: boolean): void => {
    setDenyModalOpen(open);

    if (!open) {
      setDenyReason('');
    }
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
            <Button
              type="button"
              variant="destructive"
              onClick={() => handleDenyModalOpenChange(false)}
            >
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
        // open={request.domains.includes('minecraft.net')}
        onOpenChange={(open) => {
          setReviewOpen(open);
          setCurrentKeyIndex(0);
        }}
        ariaLabel={`Review ${request.personName}'s unlock request`}
      >
        <div className="h-full w-full flex flex-col justify-center items-center">
          {request.domains.length > 1 && (
            <div className="flex flex-col items-center gap-1">
              <span className="text-xs text-stone-500">
                {currentKeyIndex + 1} / {request.domains.length}
              </span>
              <div className="flex bg-stone-200 w-24 h-2 rounded-full overflow-hidden">
                <div
                  style={{
                    width: `${(currentKeyIndex / request.domains.length) * 100}%`,
                  }}
                  className="bg-violet-500 h-full transition-[width] duration-300"
                />
              </div>
            </div>
          )}
          <div className="relative w-60 mb-8 mt-4 h-60 flex justify-center items-center">
            {keys.map((k, i) => {
              let unlocked = i < currentKeyIndex && allowStatuses[i] === 'unlocked';
              let denied = i < currentKeyIndex && allowStatuses[i] === 'denied';

              return (
                <div
                  key={k.domain}
                  style={
                    unlocked || denied
                      ? {
                          transform: `translateY(${(i + 0.5 - allowStatuses.filter((s) => s === 'unlocked' || s === 'denied').length / 2) * 40}px)`,
                        }
                      : {}
                  }
                  className={cx(
                    'border border-stone-200 rounded-xl shadow shadow-stone-300/30 p-3 bg-white h-full w-full absolute transition-[translate,opacity,rotate,scale,background-color,border-color,height,width,transform] duration-300 overflow-hidden',
                    (unlocked || denied) && '!w-4 !h-4 -translate-x-52',
                    i === currentKeyIndex && '',
                    i === currentKeyIndex + 1 &&
                      'translate-x-70 opacity-50 rotate-12 translate-y-9',
                    i > currentKeyIndex + 1 &&
                      'translate-x-140 opacity-0 rotate-45 translate-y-20',
                  )}
                >
                  <div
                    className={cx(
                      'absolute inset-0 h-full w-full flex flex-col justify-center items-center transition-[opacity] duration-300',
                      (unlocked || denied) && 'opacity-0',
                    )}
                  >
                    <div className="w-8 h-8 rounded-full flex justify-center items-center bg-stone-200/50">
                      <KeyIcon className="text-stone-600 w-4.5 h-4.5" />
                    </div>
                    <span className="text-base font-medium text-stone-900 mt-2 mb-2 w-full whitespace-pre-wrap wrap-break-word hyphens-auto text-center">
                      {keys[i].domain}
                    </span>
                    <Badge
                      color={keys[i].addressType === 'standard' ? 'neutral' : 'violet'}
                    >
                      <span className="capitalize">{keys[i].addressType} key</span>
                    </Badge>
                    <span className="text-xs text-stone-500 mt-2">For all apps</span>
                  </div>
                  <div
                    className={cx(
                      'absolute inset-0 flex justify-center items-center transition-[opacity] duration-300 bg-violet-500',
                      unlocked ? 'opacity-100' : 'opacity-0',
                    )}
                  >
                    <KeyIcon className="text-white w-3.5 h-3.5" />
                  </div>
                  <div
                    className={cx(
                      'absolute inset-0 flex justify-center items-center transition-[opacity] duration-300 bg-stone-200',
                      denied ? 'opacity-100' : 'opacity-0',
                    )}
                  >
                    <BanIcon className="text-stone-500 w-3.5 h-3.5" />
                  </div>
                </div>
              );
            })}
          </div>
          <div className="flex gap-2">
            <Button
              type="button"
              onClick={() => {
                setAllowStatuses((prev) => {
                  const newAllowStatuses = [...prev];
                  newAllowStatuses[currentKeyIndex] = 'unlocked';
                  return newAllowStatuses;
                });
                if (currentKeyIndex + 1 === request.domains.length) {
                  setAllowStatuses(Array(request.domains.length).fill('pending'));
                  setCurrentKeyIndex(0);
                } else {
                  setCurrentKeyIndex(currentKeyIndex + 1);
                }
              }}
            >
              Add key
            </Button>
            <Button type="button" onClick={() => {}} variant="ghost">
              Edit key
            </Button>
            <Button
              type="button"
              onClick={() => {
                setAllowStatuses((prev) => {
                  const newAllowStatuses = [...prev];
                  newAllowStatuses[currentKeyIndex] = 'denied';
                  return newAllowStatuses;
                });
                if (currentKeyIndex + 1 === request.domains.length) {
                  setAllowStatuses(Array(request.domains.length).fill('pending'));
                  setCurrentKeyIndex(0);
                } else {
                  setCurrentKeyIndex(currentKeyIndex + 1);
                }
              }}
              variant="ghost"
            >
              Deny
            </Button>
          </div>
        </div>
      </SlideOver>
    </div>
  );
};

export default UnlockRequestCard;
