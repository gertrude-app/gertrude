import { Badge, Divider, HStack, Text, VStack } from '@gertrude/ui';
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
  hasUnsavedChanges?: boolean;
  children: React.ReactNode;
};

const PersonSettingsExpandableSection: React.FC<PersonSettingsExpandableSectionProps> = ({
  title,
  previewChips,
  appIconUrl,
  defaultExpanded = false,
  hasUnsavedChanges = false,
  children,
}) => {
  const [expanded, setExpanded] = useState(defaultExpanded);
  const contentId = React.useId();

  return (
    <VStack className="bg-white @xl/main:border-x border-y border-stone-200 @xl/main:rounded-xl shadow shadow-stone-300/30 -mx-3 @lg/main:-mx-4 @xl/main:mx-0">
      <h2>
        <HStack
          as="button"
          type="button"
          aria-label={title}
          aria-expanded={expanded}
          aria-controls={contentId}
          justify="between"
          gap={3}
          className="w-full p-3 cursor-pointer select-none text-left rounded-xl outline-none focus-visible:ring-2 focus-visible:ring-violet-400/70 focus-visible:ring-offset-2 focus-visible:ring-offset-stone-50"
          onClick={() => setExpanded(!expanded)}
        >
          <HStack gap={4} wrap className="gap-y-0.5">
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
            <Text as="span" variant="heading">
              {title}
            </Text>
            <HStack gap={2} wrap>
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
            </HStack>
          </HStack>
          <HStack gap={2} className="shrink-0">
            {hasUnsavedChanges && (
              <Badge size="small" color="yellow">
                Unsaved changes
              </Badge>
            )}
            <ChevronRightIcon
              className={cx(
                `w-5 h-5 text-stone-600 transition-[rotate] duration-200 shrink-0`,
                expanded && `rotate-90`,
              )}
            />
          </HStack>
        </HStack>
      </h2>
      <div
        id={contentId}
        role="region"
        aria-label={`${title} settings`}
        aria-hidden={!expanded}
        inert={!expanded}
        className={cx(
          expanded ? `h-auto opacity-100` : `h-0 opacity-0 pointer-events-none`,
          `overflow-hidden transition-[height,opacity] duration-200`,
        )}
      >
        <Divider />
        <div className="p-3">{children}</div>
      </div>
    </VStack>
  );
};

export default PersonSettingsExpandableSection;
