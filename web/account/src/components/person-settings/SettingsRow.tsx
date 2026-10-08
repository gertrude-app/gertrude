import { HStack, Text, Toggle, VStack } from '@gertrude/ui';
import cx from 'clsx';
import { InfoIcon } from 'lucide-react';
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
    }
  | {
      type: `alwaysOn`;
    }
);

const SettingsRow: React.FC<Props> = (props) => {
  const showWarning = !!(props.warning && props.showWarning);
  const warningBeforeContent = props.warningPosition === `beforeContent`;
  const contentVisible = props.type === `alwaysOn` || props.enabled;
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
        <HStack justify="between" className="p-3 pr-5" gap={5}>
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
            </HStack>
          )}
        </HStack>
        {warningBeforeContent && warningBanner}
        {props.children && (
          <div
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
