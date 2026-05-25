import React from 'react';
import { ArrowRightIcon } from 'lucide-react';
import type { UnlockRequest } from '#/lib/mock-data';
import RightSidebarCard from './RightSidebarCard';

interface Props {
  allUnlockRequests: Array<UnlockRequest>;
}

const UnlockRequestsPreviewCard: React.FC<Props> = ({ allUnlockRequests }) => {
  return (
    <RightSidebarCard
      title="Unlock Requests"
      links={[
        {
          text: 'View all',
          href: '#todo',
          icon: ArrowRightIcon,
          iconPosition: 'right',
          variant: 'ghost',
        },
      ]}
    >
      <div className="bg-white border border-stone-200 rounded-xl p-3 flex flex-col shadow shadow-stone-300/30">
        {allUnlockRequests.slice(0, 3).map((r) => (
          <div
            key={`${r.personName}-${r.domains.join(',')}`}
            className="flex flex-col border-b last:border-b-0 border-stone-200/80 py-3 first:pt-0 last:pb-0 cursor-pointer"
          >
            <span className="text-sm font-medium text-stone-900">{r.personName}</span>
            <div className="flex flex-wrap gap-1 mt-0.5">
              {r.domains.slice(0, 4).map((d) => (
                <span
                  key={d}
                  className="text-[10px] font-medium text-stone-600 bg-stone-50 border border-stone-200 px-1 rounded"
                >
                  {d}
                </span>
              ))}
              {r.domains.length > 4 && (
                <span className="text-stone-500 text-[10px]">
                  + {r.domains.length - 4} more
                </span>
              )}
            </div>
            {r.reason && (
              <p className="text-stone-800 bg-stone-200 px-3.5 py-2.5 rounded-2xl rounded-tl w-fit self-start text-sm mt-3">
                {r.reason}
              </p>
            )}
          </div>
        ))}
      </div>
    </RightSidebarCard>
  );
};

export default UnlockRequestsPreviewCard;
