import React from 'react';
import cx from 'classnames';
import Button from '../../../../Button';

type Props = {
  className?: string;
  lookaheadTitle: string;
  activeTitle: string;
  title: React.ReactNode;
  children: React.ReactNode;
  currentStep: number;
  setCurrentStep(num: number): void;
  index: number; // starting from 1, to make it line up with the steps
  mode: 'edit' | 'create';
  isLast?: boolean;
  canAdvance?: boolean;
};

const KeyCreationStep: React.FC<Props> = ({
  className,
  title,
  activeTitle,
  currentStep,
  index,
  children,
  isLast = false,
  lookaheadTitle,
  mode,
  canAdvance = true,
}) => {
  const open = currentStep === index;
  return (
    <div className={cx(`flex items-stretch max-w-2xl min-h-[64px]`, className)}>
      {mode === `create` && (
        <div
          className={cx(
            `w-8 sm:w-12 flex justify-center items-center relative flex-shrink-0`,
          )}
        >
          <div
            className={cx(
              `h-full border-r-2 border-dashed border-gray-300 absolute`,
              index === 1 && `h-1/2 bottom-0`,
              isLast && `h-1/2 top-0`,
            )}
          />
          <div
            className={cx(
              `relative w-4 h-4 rounded-full border-2`,
              index < currentStep && `border-indigo-500 bg-indigo-500`,
              index === currentStep && `border-indigo-500 bg-indigo-50`,
              index > currentStep && `border-gray-300 bg-gray-50`,
            )}
          />
        </div>
      )}
      {index > currentStep && mode === `create` ? (
        <h2 className="text-gray-500 text-lg flex items-center">{lookaheadTitle}</h2>
      ) : (
        <div
          className={cx(
            `rounded-2xl shadow-lg flex-grow my-2 bg-white`,
            open ? `border-2 border-violet-400` : `border`,
          )}
        >
          <button
            className="flex justify-between w-full items-center cursor-pointer hover:bg-gray-50 transition duration-100 p-4 rounded-2xl outline-none focus:ring-2 ring-violet-400 [transition:200ms] text-left"
            onClick={() => {}}
          >
            {index === currentStep ? (
              <h2 className="font-medium text-gray-900 text-lg">{activeTitle}</h2>
            ) : (
              title
            )}
            <i
              className={cx(
                `fa-solid fa-chevron-down text-gray-500 transition duration-150`,
                open && `-rotate-180`,
              )}
            />
          </button>
          {open && (
            <div className="p-2 sm:p-4">
              {children}
              {((mode === `create` && currentStep === index) || isLast) && (
                <div
                  className={cx(
                    `flex items-center mt-6`,
                    index === 1 ? `justify-end` : `justify-between`,
                  )}
                >
                  {index !== 1 && (
                    <Button
                      type="button"
                      onClick={() => {}}
                      color="secondary-white"
                      small
                    >
                      <i className="fa-solid fa-arrow-left mr-2" />
                      Back
                    </Button>
                  )}
                  <Button
                    type="button"
                    onClick={() => {}}
                    color="primary-violet"
                    small
                    disabled={!canAdvance}
                  >
                    {isLast ? `Create key` : `Next`}
                    {
                      <i
                        className={`fa-solid fa-${isLast ? `key` : `arrow-right`} ml-2`}
                      />
                    }
                  </Button>
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
