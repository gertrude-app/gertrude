import { Button } from '@shared/components';
import cx from 'classnames';
import React, { useContext, useEffect, useMemo, useState } from 'react';
import type { AlwaysBlockedGroup } from '../onboarding-store';
import InformationModal from '../InformationModal';
import OnboardingContext from '../OnboardingContext';
import * as Onboarding from '../UtilityComponents';

interface Props {
  groups: AlwaysBlockedGroup[];
  preselected: UUID[];
}

const AlwaysBlockedGroups: React.FC<Props> = ({ groups, preselected }) => {
  const { emit } = useContext(OnboardingContext);
  const [selected, setSelected] = useState<Set<UUID>>(new Set(preselected));
  const [infoOpenFor, setInfoOpenFor] = useState<UUID | null>(null);

  useEffect(() => {
    setSelected(new Set(preselected));
  }, [preselected]);

  const sortedGroups = useMemo(() => {
    const recommended = new Set(preselected);
    return [...groups].sort(
      (a, b) => Number(recommended.has(b.id)) - Number(recommended.has(a.id)),
    );
  }, [groups, preselected]);

  const toggle = (id: UUID): void =>
    setSelected((prev) => {
      const next = new Set(prev);
      if (next.has(id)) next.delete(id);
      else next.add(id);
      return next;
    });

  const infoGroup = sortedGroups.find((g) => g.id === infoOpenFor);

  return (
    <Onboarding.Centered className="!justify-start pt-24">
      <InformationModal open={infoOpenFor !== null} onClose={() => setInfoOpenFor(null)}>
        {infoGroup && (
          <>
            <h2 className="text-2xl font-bold text-slate-900 mb-4">{infoGroup.name}</h2>
            <p>{infoGroup.longDescription}</p>
          </>
        )}
      </InformationModal>
      <div className="flex flex-col items-center max-w-2xl w-full">
        <div className="flex items-center gap-3">
          <span className="w-11 h-11 rounded-2xl bg-gradient-to-br from-violet-400 to-fuchsia-500 flex items-center justify-center shadow-lg shadow-violet-200/70">
            <i className="fa-solid fa-ban text-white text-lg" />
          </span>
          <Onboarding.Heading>
            <em className="xunderline">Always</em> blocked
          </Onboarding.Heading>
        </div>

        <Onboarding.Text className="mt-5 max-w-xl" centered>
          Most parents want a few things to stay blocked <b>no matter what</b>&mdash;even
          {` `}
          <em>during a filter suspension.</em> These are our recommendations, but you can
          customize or add custom blocks later from the parent website.
        </Onboarding.Text>

        <div className="mt-8 space-y-2 w-full">
          {sortedGroups.map((group) => {
            const isSelected = selected.has(group.id);
            return (
              <div
                key={group.id}
                role="button"
                tabIndex={-1}
                onClick={() => toggle(group.id)}
                className={cx(
                  `flex items-center gap-3 px-3.5 py-3 rounded-xl border transition-colors cursor-pointer`,
                  isSelected
                    ? `border-violet-400 bg-violet-50/60`
                    : `border-slate-400 bg-transparent`,
                )}
              >
                <div
                  className={cx(
                    `w-5 h-5 rounded-md border-2 flex items-center justify-center flex-shrink-0 self-start mt-0.5 transition-colors`,
                    isSelected
                      ? `bg-violet-500 border-violet-500`
                      : `bg-white/60 border-slate-300`,
                  )}
                >
                  {isSelected && (
                    <i className="fa-solid fa-check text-white text-[10px]" />
                  )}
                </div>
                <div className="flex-1 min-w-0 text-left">
                  <div
                    className={cx(
                      `font-semibold text-sm leading-tight`,
                      isSelected ? `text-violet-900` : `text-slate-900`,
                    )}
                  >
                    {group.name}
                  </div>
                  <div
                    className={cx(
                      `text-xs leading-snug mt-0.5`,
                      isSelected ? `text-violet-700/80` : `text-slate-500`,
                    )}
                  >
                    {group.description}
                  </div>
                </div>
                <button
                  type="button"
                  tabIndex={-1}
                  onClick={(e) => {
                    e.stopPropagation();
                    setInfoOpenFor(group.id);
                  }}
                  className="w-7 h-7 rounded-full flex items-center justify-center flex-shrink-0 text-violet-400 hover:text-violet-600 transition-colors"
                  aria-label={`More about ${group.name}`}
                >
                  <i className="fa-solid fa-circle-info text-lg" />
                </button>
              </div>
            );
          })}
        </div>

        <Button
          type="button"
          color="primary"
          size="large"
          className="mt-8"
          onClick={() =>
            emit({ case: `alwaysBlockedGroupsSelected`, ids: [...selected] })
          }
          tabIndex={-1}
        >
          Continue
          <i className="fa-solid fa-arrow-right ml-3" />
        </Button>
      </div>
    </Onboarding.Centered>
  );
};

export default AlwaysBlockedGroups;
