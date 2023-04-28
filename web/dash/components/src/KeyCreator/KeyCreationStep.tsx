import React from 'react';
import cx from 'classnames';
import { Button } from '@shared/components';
import { EditKey } from '@dash/keys';

type Props = {
  className?: string;
  lookaheadTitle: string;
  activeTitle: string;
  title: React.ReactNode;
  children: React.ReactNode;
  ownStep: EditKey.Step;
  activeStep: EditKey.Step;
  mode: 'edit' | 'create';
  canAdvance?: boolean;
  update(event: EditKey.Event): unknown;
};

const KeyCreationStep: React.FC<Props> = ({
  className,
  title,
  activeTitle,
  ownStep,
  activeStep,
  children,
  lookaheadTitle,
  mode,
  canAdvance = true,
  update,
}) => {
  const open = ownStep === activeStep;
  const isFirst = ownStep === EditKey.Step.SetKeyType;
  const isLast = ownStep === EditKey.Step.Comment;
  const isActive = ownStep === activeStep;
  const isBeforeActive = ownStep < activeStep;
  const isAfterActive = ownStep > activeStep;
  return (
    <div className={cx(`flex items-stretch min-h-[64px]`, className)}>
      {mode === `create` && (
        <div
          className={cx(
            `w-8 sm:w-12 flex justify-center items-center relative flex-shrink-0`,
          )}
        >
          <div
            className={cx(
              `h-full border-r-2 border-dashed border-slate-300 absolute`,
              isFirst && `h-1/2 bottom-0`,
              isLast && `h-1/2 top-0`,
            )}
          />
          <div
            className={cx(
              `relative w-4 h-4 rounded-full border-2`,
              isBeforeActive && `border-indigo-500 bg-indigo-500`,
              isActive && `border-indigo-500 bg-indigo-50`,
              isAfterActive && `border-slate-300 bg-slate-50`,
            )}
          />
        </div>
      )}
      {isAfterActive && mode === `create` ? (
        <h2 className="text-slate-500 text-lg flex items-center">{lookaheadTitle}</h2>
      ) : (
        <div
          className={cx(
            `rounded-2xl shadow-lg flex-grow my-2 bg-white`,
            open ? `border-2 border-violet-400` : `border`,
            mode === `create` ? `max-w-[calc(100%-40px)]` : `max-w-full`,
          )}
        >
          <div
            className="flex justify-between w-full items-center cursor-pointer hover:bg-slate-50 transition duration-100 p-4 rounded-2xl outline-none [transition:200ms] text-left"
            onClick={() => update({ type: `inactiveStepClicked`, step: ownStep })}
          >
            {isActive ? (
              <h2 className="font-medium text-slate-900 text-lg">{activeTitle}</h2>
            ) : (
              title
            )}
            <i
              className={cx(
                `pl-2 fa-solid fa-chevron-down text-slate-500 transition duration-150`,
                open && `-rotate-180`,
              )}
            />
          </div>
          {open && (
            <div className="p-2 sm:p-4">
              {children}
              {((mode === `create` && activeStep === ownStep) || isLast) && (
                <div
                  className={cx(
                    `flex items-center mt-6`,
                    isFirst ? `justify-end` : `justify-between`,
                  )}
                >
                  {ownStep > EditKey.Step.SetKeyType && (
                    <Button
                      type="button"
                      onClick={() => update({ type: `prevStepClicked` })}
                      color="tertiary"
                    >
                      <i className="fa-solid fa-arrow-left mr-2" />
                      Back
                    </Button>
                  )}
                  {!isLast && (
                    <Button
                      type="button"
                      onClick={() => update({ type: `nextStepClicked` })}
                      color="secondary"
                      disabled={!canAdvance}
                      testId="keycreator-next-step"
                    >
                      Next <i className="fa-solid fa-arrow-right ml-2" />
                    </Button>
                  )}
                </div>
              )}
            </div>
          )}
        </div>
      )}
    </div>
  );
};

export default KeyCreationStep;
