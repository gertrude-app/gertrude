import { Link } from '@tanstack/react-router';
import { ArrowRightIcon } from 'lucide-react';
import React from 'react';
import type { SuspensionRequest } from '#/lib/mock';
import RightColumnCard from './RightColumnCard';

interface Props {
  allSuspensionRequests: Array<SuspensionRequest>;
}

const SuspensionRequetsPreviewCard: React.FC<Props> = ({ allSuspensionRequests }) => (
  <RightColumnCard
    title="Suspension Requests"
    links={[
      {
        text: `View all`,
        href: `/requests/suspension`,
        icon: ArrowRightIcon,
        iconPosition: `right`,
        variant: `ghost`,
      },
    ]}
  >
    <div className="bg-white border border-stone-200 rounded-xl p-3 flex flex-col shadow shadow-stone-300/30">
      {allSuspensionRequests.slice(0, 3).map((r) => (
        <Link
          key={r.id}
          to="/requests/suspension"
          className="flex flex-col border-b last:border-b-0 border-stone-200/80 py-3 first:pt-0 last:pb-0 cursor-pointer gap-1.5"
        >
          <div className="flex flex-col">
            <span className="text-sm font-medium text-stone-900">{r.personName}</span>
            <span className="text-xs text-stone-600">{r.duration}</span>
          </div>
          {r.reason && (
            <p className="text-stone-800 bg-stone-200 px-3.5 py-2.5 rounded-2xl rounded-tl w-fit self-start text-sm">
              {r.reason}
            </p>
          )}
        </Link>
      ))}
    </div>
  </RightColumnCard>
);

export default SuspensionRequetsPreviewCard;
