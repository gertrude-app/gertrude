import { HStack, Text, Toggle, VStack } from '@gertrude/ui';
import cx from 'clsx';
import { ChevronDownIcon, InfoIcon } from 'lucide-react';
import React from 'react';

type Props = {
  title: string;
  description: string;
  children?: React.ReactNode;
  badge?: React.ReactNode;
  warning?: string;
  showWarning?: boolean;
  warningPosition?: `beforeContent` | `afterContent`;
} & (
  | {
      type: `toggle`;
      enabled: boolean;
      disabled?: boolean;
      setEnabled: (enabled: boolean) => void;
      toggleLabel?: string;
      expanded?: boolean;
      onExpandedChange?: (expanded: boolean) => void;
    }
  | {
      type: `alwaysOn`;
    }
);

const SettingsRow: React.FC<Props> = (props) => {
  const contentId = React.useId();
  const showWarning = !!(props.warning && props.showWarning);
  const warningBeforeContent = props.warningPosition === `beforeContent`;
  const expandable = props.type === `toggle` && props.onExpandedChange !== undefined;
  const contentVisible =
    props.type === `alwaysOn` || (expandable ? !!props.expanded : props.enabled);
  const warningBanner = showWarning ? (
    <HStack align="start" gap={3} className="p-3 bg-amber-200/30">
      <InfoIcon className="h-4 w-4 text-amber-800 mt-0.5 shrink-0" />
      <Text as="p" variant="warning">
        {props.warning}
      </Text>
    </HStack>
  ) : null;

  return (
    <VStack className="@lg/main:border-x border-y border-stone-200 @lg/main:rounded-md overflow-hidden -mx-3 @lg/main:mx-0">
      <VStack
        className={cx(
          `bg-stone-50 border-stone-200`,
          showWarning && !warningBeforeContent && `border-b`,
        )}
      >
        <HStack
          justify="between"
          className={cx(`p-3`, expandable ? `pr-[18px]` : `pr-5`)}
          gap={5}
        >
          <VStack className="flex-1 min-w-0">
            <Text variant="bodyStrong">{props.title}</Text>
            <Text variant="bodySubtle">{props.description}</Text>
          </VStack>
          {(props.badge || props.type === `toggle`) && (
            <HStack gap={2} className="shrink-0">
              {props.badge}
              {props.type === `toggle` && (
                <Toggle
                  checked={props.enabled}
                  setChecked={props.setEnabled}
                  disabled={props.disabled}
                  ariaLabel={props.toggleLabel ?? props.title}
                />
              )}
              {props.type === `toggle` && props.onExpandedChange && (
                <button
                  type="button"
                  aria-expanded={!!props.expanded}
                  aria-controls={props.children ? contentId : undefined}
                  aria-label={`${props.expanded ? `Hide` : `Show`} ${props.title} options`}
                  onClick={() => props.onExpandedChange?.(!props.expanded)}
                  className="flex h-7 w-7 cursor-pointer items-center justify-center rounded-full text-stone-400 transition-colors hover:bg-stone-200/60 hover:text-stone-600 outline-none focus-visible:ring-2 focus-visible:ring-violet-400/70"
                >
                  <ChevronDownIcon
                    className={cx(
                      `h-5 w-5 transition-transform duration-200`,
                      !props.expanded && `-rotate-90`,
                    )}
                  />
                </button>
              )}
            </HStack>
          )}
        </HStack>
        {warningBeforeContent && warningBanner}
        {props.children && (
          <div
            id={contentId}
            aria-hidden={!contentVisible}
            inert={!contentVisible}
            className={cx(
              `overflow-hidden transition-[height,opacity] duration-200`,
              contentVisible ? `h-auto opacity-100` : `h-0 opacity-0 pointer-events-none`,
            )}
          >
            <div className="px-3 pb-3">{props.children}</div>
          </div>
        )}
      </VStack>
      {!warningBeforeContent && warningBanner}
    </VStack>
  );
};

export default SettingsRow;
