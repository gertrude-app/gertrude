import { Button } from '@shared/components';
import { inflect } from '@shared/string';
import React from 'react';
import type { DashboardWidgets_v3 } from '@dash/types';
import DashboardWidget from './DashboardWidget';
import WidgetTitle from './WidgetTitle';

type Props = {
  className?: string;
  unlockRequests: DashboardWidgets_v3.Output[`unlockRequests`];
};

type UnlockReq = DashboardWidgets_v3.Output[`unlockRequests`][number];

type ChildGroup = {
  childId: UUID;
  childName: string;
  count: number;
  preview: UnlockReq[];
};

function groupByChild(
  requests: DashboardWidgets_v3.Output[`unlockRequests`],
): ChildGroup[] {
  const map = new Map<UUID, { group: ChildGroup; all: UnlockReq[] }>();
  for (const req of requests) {
    const existing = map.get(req.childId);
    if (existing) {
      existing.group.count++;
      existing.all.push(req);
    } else {
      map.set(req.childId, {
        group: {
          childId: req.childId,
          childName: req.childName,
          count: 1,
          preview: [],
        },
        all: [req],
      });
    }
  }
  for (const { group, all } of map.values()) {
    group.preview = pickPreview(all, 3);
  }
  return [...map.values()].map((e) => e.group).sort((a, b) => b.count - a.count);
}

function pickPreview(requests: UnlockReq[], max: number): UnlockReq[] {
  const withComment: UnlockReq[] = [];
  const withoutComment: UnlockReq[] = [];
  for (const r of requests) {
    (r.comment ? withComment : withoutComment).push(r);
  }
  const sorted = [...withComment, ...withoutComment];
  const picked: UnlockReq[] = [];
  const seenTargets = new Set<string>();
  for (const r of sorted) {
    if (picked.length >= max) break;
    if (!seenTargets.has(r.target)) {
      seenTargets.add(r.target);
      picked.push(r);
    }
  }
  if (picked.length < max) {
    for (const r of sorted) {
      if (picked.length >= max) break;
      if (!picked.includes(r)) picked.push(r);
    }
  }
  return picked;
}

const UnlockRequestsWidget: React.FC<Props> = ({ className, unlockRequests }) => {
  const groups = groupByChild(unlockRequests);
  return (
    <DashboardWidget className={className}>
      <WidgetTitle icon="unlock" text="Mac unlock requests" />
      <div className="divide-y divide-slate-100">
        {groups.map((group) => (
          <div key={group.childId} className="py-4 first:pt-0 last:pb-0">
            <div className="flex items-center gap-2.5 ml-1.5">
              <div className="w-6 h-6 rounded-full bg-violet-100 flex items-center justify-center shrink-0">
                <i className="fa-solid fa-user text-violet-300 text-[10px]" />
              </div>
              <span className="font-semibold text-slate-800 text-[17px]">
                {group.childName}
              </span>
              <span className="text-[11px] font-semibold px-2 py-0.5 rounded-full bg-violet-50 text-violet-600 shrink-0">
                {group.count} {inflect(`request`, group.count)}
              </span>
            </div>
            <div className="ml-9 mt-2 border-l-2 border-violet-100 pl-3 space-y-2.5">
              {group.preview.map((req) => (
                <div key={req.id} className="leading-tight">
                  <span className="font-mono text-[12px] text-violet-400 truncate block">
                    {req.target}
                  </span>
                  {req.comment && (
                    <span className="text-slate-400 italic text-[11px]">
                      &ldquo;{req.comment}&rdquo;
                    </span>
                  )}
                </div>
              ))}
              {group.count > group.preview.length && (
                <span className="text-[11px] text-slate-300">
                  +{group.count - group.preview.length} more
                </span>
              )}
            </div>
            <div className="ml-9 mt-3">
              <Button
                type="link"
                to={`/children/${group.childId}/unlock-requests`}
                color="secondary"
                size="medium"
              >
                Review &rarr;
              </Button>
            </div>
          </div>
        ))}
      </div>
    </DashboardWidget>
  );
};

export default UnlockRequestsWidget;
