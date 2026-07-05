import cx from 'clsx';
import { ChevronRightIcon } from 'lucide-react';
import React, { useState } from 'react';
import PreviewChip, { type PreviewChipValue } from './PreviewChip';

export type PersonSettingsPreviewChip = {
  title: string;
  values: PreviewChipValue[];
} | null;

export type PersonSettingsExpandableSectionProps = {
  title: string;
  previewChips: PersonSettingsPreviewChip[];
  appIconUrl?: string;
  defaultExpanded?: boolean;
  children: React.ReactNode;
};

const PersonSettingsExpandableSection: React.FC<PersonSettingsExpandableSectionProps> = ({
  title,
  previewChips,
  appIconUrl,
  defaultExpanded = false,
  children,
}) => {
  const [expanded, setExpanded] = useState(defaultExpanded);

  return (
    <div className="flex flex-col bg-white @xl/main:border-x border-y border-stone-200 @xl/main:rounded-xl shadow shadow-stone-300/30 -mx-3 @lg/main:-mx-4 @xl/main:mx-0">
      <div
        className="flex justify-between gap-3 p-3 items-center cursor-pointer select-none"
        onClick={() => setExpanded(!expanded)}
      >
        <div className="flex items-center gap-x-4 gap-y-0.5 flex-wrap">
          {appIconUrl && (
            <div className="relative">
              <img
                className="w-8 h-8 rounded-[9px] absolute blur-xs opacity-40"
                src={appIconUrl}
                alt=""
              />
              <img
                className="w-8 h-8 shadow rounded-[9px] shadow-stone-300/30 relative"
                src={appIconUrl}
                alt=""
              />
            </div>
          )}
          <span className="text-lg font-medium text-stone-900">{title}</span>
          <div className="flex gap-2 flex-wrap">
            {previewChips.map((preview) => {
              if (preview) {
                return (
                  <PreviewChip
                    key={preview.title}
                    label={preview.title}
                    values={preview.values}
                  />
                );
              }
              return null;
            })}
          </div>
        </div>
        <ChevronRightIcon
          className={cx(
            `w-5 h-5 text-stone-600 transition-[rotate] duration-200 shrink-0`,
            expanded && `rotate-90`,
          )}
        />
      </div>
      <div
        className={cx(
          expanded ? `h-auto opacity-100` : `h-0 opacity-0`,
          `overflow-hidden transition-[height,opacity] duration-200`,
        )}
      >
        <div className="p-3 border-t border-stone-200">{children}</div>
      </div>
    </div>
  );
};

export default PersonSettingsExpandableSection;
