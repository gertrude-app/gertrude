import { ArrowRightIcon } from 'lucide-react';
import React from 'react';
import type { UnlockRequest } from '#/components/types';
import RightColumnCard from './RightColumnCard';

interface Props {
  unlockRequests: UnlockRequest[];
  viewAllHref: string;
}

const UnlockRequestsPreviewCard: React.FC<Props> = ({ unlockRequests, viewAllHref }) => (
  <RightColumnCard
    title="Unlock Requests"
    links={[
      {
        text: `View all`,
        href: viewAllHref,
        icon: ArrowRightIcon,
        iconPosition: `right`,
        variant: `ghost`,
      },
    ]}
  >
    <div className="bg-white border border-stone-200 rounded-xl p-3 flex flex-col shadow shadow-stone-300/30">
      {unlockRequests.slice(0, 3).map((request) => (
        <a
          key={request.id}
          href={request.reviewHref ?? viewAllHref}
          className="flex flex-col border-b last:border-b-0 border-stone-200/80 py-3 first:pt-0 last:pb-0 cursor-pointer"
        >
          <span className="text-sm font-medium text-stone-900">{request.personName}</span>
          <div className="flex flex-wrap gap-1 mt-0.5">
            {request.domains.slice(0, 4).map((domain) => (
              <span
                key={domain}
                className="text-[10px] font-medium text-stone-600 bg-stone-50 border border-stone-200 px-1 rounded"
              >
                {domain}
              </span>
            ))}
            {request.domains.length > 4 && (
              <span className="text-stone-500 text-[10px]">
                + {request.domains.length - 4} more
              </span>
            )}
          </div>
          {request.reason && (
            <p className="text-stone-800 bg-stone-200 px-3.5 py-2.5 rounded-2xl rounded-tl w-fit self-start text-sm mt-3">
              {request.reason}
            </p>
          )}
        </a>
      ))}
    </div>
  </RightColumnCard>
);

export default UnlockRequestsPreviewCard;
