import React from 'react';
import { Link } from '@tanstack/react-router';
import { ArrowRightIcon } from 'lucide-react';
import type { UnlockRequest } from '#/lib/mock-data';
import RightColumnCard from './RightColumnCard';

interface Props {
  allUnlockRequests: Array<UnlockRequest>;
}

const UnlockRequestsPreviewCard: React.FC<Props> = ({ allUnlockRequests }) => {
  return (
    <RightColumnCard
      title="Unlock Requests"
      links={[
        {
          text: 'View all',
          href: '/requests/unlock',
          icon: ArrowRightIcon,
          iconPosition: 'right',
          variant: 'ghost',
        },
      ]}
    >
      <div className="bg-white border border-stone-200 rounded-xl p-3 flex flex-col shadow shadow-stone-300/30">
        {allUnlockRequests.slice(0, 3).map((r) => (
          <Link
            key={`${r.personName}-${r.domains.join(',')}`}
            to="/requests/unlock"
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
          </Link>
        ))}
      </div>
    </RightColumnCard>
  );
};

export default UnlockRequestsPreviewCard;
