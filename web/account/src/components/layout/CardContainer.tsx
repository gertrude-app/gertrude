import { HStack, Stack, Text } from '@gertrude/ui';
import cx from 'clsx';
import React from 'react';

interface Props {
  children?: React.ReactNode;
  heading?: React.ReactNode;
  subheading?: React.ReactNode;
  buttons?: React.ReactNode;
  dangerZone?: boolean;
  className?: string;
}

const CardContainer: React.FC<Props> = ({
  children,
  heading,
  subheading,
  buttons,
  dangerZone,
  className,
}) => {
  const hasHeading = heading !== undefined && heading !== null;
  const hasSubheading = subheading !== undefined && subheading !== null;
  const hasHeaderText = hasHeading || hasSubheading;
  const hasHeader = hasHeaderText || buttons !== undefined;

  return (
    <div
      className={cx(
        `px-3 @lg/main:px-4 @xl/main:px-3 @3xl/main:px-6 py-4 @xl/main:py-3 @3xl/main:py-6 -mx-3 @lg/main:-mx-4 @xl/main:-mx-3 @3xl/main:-mx-6 @xl/main:rounded-2xl @xl/main:border-x border-y bg-dots`,
        `border-stone-200/70 bg-stone-50/50`,
        className,
      )}
    >
      {hasHeader && (
        <Stack
          direction={{ default: `vertical`, '@2xl/main': `horizontal` }}
          gap={3}
          align={{ default: `stretch`, '@2xl/main': `start` }}
          justify={hasHeaderText ? `between` : `end`}
        >
          {hasHeaderText && (
            <div className="min-w-0">
              {hasHeading && (
                <Text
                  as="h2"
                  variant="heading"
                  className={cx(dangerZone ? `text-red-950/90` : `text-stone-900`)}
                >
                  {heading}
                </Text>
              )}
              {hasSubheading && (
                <Text
                  as="p"
                  variant="bodyMuted"
                  className={cx(dangerZone && `text-red-900/70`)}
                >
                  {subheading}
                </Text>
              )}
            </div>
          )}
          {buttons !== undefined && (
            <HStack
              as="div"
              wrap
              gap={2}
              justify={{ '@2xl/main': `end` }}
              className="shrink-0"
            >
              {buttons}
            </HStack>
          )}
        </Stack>
      )}
      {children}
    </div>
  );
};

export default CardContainer;
