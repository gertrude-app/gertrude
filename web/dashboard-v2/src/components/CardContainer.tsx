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
        <div
          className={cx(
            `flex flex-col gap-3 @2xl/main:flex-row @2xl/main:items-start`,
            hasHeaderText ? `@2xl/main:justify-between` : `@2xl/main:justify-end`,
          )}
        >
          {hasHeaderText && (
            <div className="min-w-0">
              {hasHeading && (
                <h2
                  className={cx(
                    `text-lg font-medium`,
                    dangerZone ? `text-red-950/90` : `text-stone-900`,
                  )}
                >
                  {heading}
                </h2>
              )}
              {hasSubheading && (
                <p
                  className={cx(
                    `text-sm`,
                    dangerZone ? `text-red-900/70` : `text-stone-500`,
                  )}
                >
                  {subheading}
                </p>
              )}
            </div>
          )}
          {buttons !== undefined && (
            <div className="flex shrink-0 flex-wrap items-center gap-2 @2xl/main:justify-end">
              {buttons}
            </div>
          )}
        </div>
      )}
      {children}
    </div>
  );
};

export default CardContainer;
