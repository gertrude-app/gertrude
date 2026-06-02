import React from 'react';
import { Button } from '@gertrude/ui';
import type { UnlockRequest } from '#/lib/mock-data';

interface Props {
  request: UnlockRequest;
}

const UnlockRequestCard: React.FC<Props> = ({ request }) => {
  const [showAllDomains, setShowAllDomains] = React.useState(false);
  const visibleDomains = showAllDomains ? request.domains : request.domains.slice(0, 4);
  const hiddenDomainCount = request.domains.length - visibleDomains.length;

  return (
    <div
      className="flex cursor-pointer flex-col gap-3 rounded-2xl border border-stone-200 bg-white p-4 shadow-md shadow-stone-300/30 transition-colors hover:bg-stone-50/60"
      onClick={() => setShowAllDomains(!showAllDomains)}
    >
      <div className="flex flex-col gap-1.5">
        <h2 className="text-lg font-medium text-stone-900">{request.personName}</h2>
        <div className="flex flex-wrap gap-1">
          {visibleDomains.map((domain) => (
            <span
              key={domain}
              className="rounded-md border border-stone-200 bg-stone-50 px-1.5 py-0.5 text-xs font-medium text-stone-700"
            >
              {domain}
            </span>
          ))}
          {hiddenDomainCount > 0 && (
            <span className="text-xs text-stone-500">+ {hiddenDomainCount} more</span>
          )}
        </div>
      </div>
      {request.reason && (
        <p className="w-fit self-start rounded-2xl rounded-tl bg-stone-200 px-3.5 py-2.5 text-sm text-stone-800">
          {request.reason}
        </p>
      )}
      <div className="mt-auto flex justify-end" onClick={(event) => event.stopPropagation()}>
        <Button type="button" onClick={() => {}} size="small">
          Review
        </Button>
      </div>
    </div>
  );
};

export default UnlockRequestCard;
