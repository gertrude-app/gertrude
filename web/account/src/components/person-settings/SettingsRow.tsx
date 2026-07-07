import { HStack, Text, Toggle, VStack } from '@gertrude/ui';
import cx from 'clsx';
import { InfoIcon } from 'lucide-react';
import React from 'react';

type Props = {
  title: string;
  description: string;
  children?: React.ReactNode;
  warning?: string;
  showWarning?: boolean;
} & (
  | {
      type: `toggle`;
      enabled: boolean;
      setEnabled: (enabled: boolean) => void;
    }
  | {
      type: `alwaysOn`;
    }
);

const SettingsRow: React.FC<Props> = (props) => {
  const showWarning = !!(props.warning && props.showWarning);

  return (
    <VStack className="@lg/main:border-x border-y border-stone-200 @lg/main:rounded-md -mx-3 @lg/main:mx-0">
      <VStack
        className={cx(
          `bg-stone-50 rounded-t-md border-stone-200`,
          showWarning ? `border-b` : `rounded-b-md`,
        )}
      >
        <HStack justify="between" className="p-3 pr-5" gap={5}>
          <VStack>
            <Text variant="bodyStrong">{props.title}</Text>
            <Text variant="bodySubtle">{props.description}</Text>
          </VStack>
          {props.type === `toggle` && (
            <Toggle checked={props.enabled} setChecked={props.setEnabled} />
          )}
        </HStack>
        {props.children && (
          <div
            className={cx(
              `overflow-hidden transition-[height,opacity] duration-200`,
              props.type === `alwaysOn` || props.enabled
                ? `h-auto opacity-100`
                : `h-0 opacity-0`,
            )}
          >
            <div className="px-3 pb-3">{props.children}</div>
          </div>
        )}
      </VStack>
      {showWarning && (
        <HStack align="start" gap={3} className="p-3 bg-amber-200/30 rounded-b-md">
          <InfoIcon className="h-4 w-4 text-amber-800 mt-0.5 shrink-0" />
          <Text as="p" variant="warning">
            {props.warning}
          </Text>
        </HStack>
      )}
    </VStack>
  );
};

export default SettingsRow;
