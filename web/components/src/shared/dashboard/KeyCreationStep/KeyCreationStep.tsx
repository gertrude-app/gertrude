import React, { useState } from 'react';
import cx from 'classnames';
import Button from '../../Button';

type Props = {
  className?: string;
  title: React.ReactNode;
  children: React.ReactNode;
  currentStep: number;
  setCurrentStep(num: number): void;
  index: number; // starting from 1, to make it line up with the steps
  numSteps: number;
  stepName: string;
  mode: 'edit' | 'create';
};

const KeyCreationStep: React.FC<Props> = ({
  className,
  title,
  currentStep,
  setCurrentStep,
  index,
  children,
  numSteps,
  stepName,
  mode,
}) => {
  const [open, setOpen] = useState(true);
  return (
    <div
      className={cx(
        `flex items-stretch max-w-2xl`,
        index > currentStep && `h-16`,
        className,
      )}
    >
      <div className={cx(`w-12 flex justify-center items-center relative flex-shrink-0`)}>
        <div
          className={cx(
            `h-full border-r-2 border-dashed border-gray-300 absolute`,
            index === 1 && `h-1/2 bottom-0`,
            index === numSteps && `h-1/2 top-0`,
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
      {index > currentStep ? (
        <h2 className="text-gray-500 text-lg flex items-center">{stepName}</h2>
      ) : (
        <div className="rounded-2xl shadow-lg flex-grow my-2 bg-white border">
          <button
            className="flex justify-between w-full items-center cursor-pointer hover:bg-gray-50 transition duration-100 p-4 rounded-2xl outline-none focus:ring-2 ring-violet-400 [transition:200ms] text-left"
            onClick={() => setOpen(!open)}
          >
            {title}
            <i
              className={cx(
                `fa-solid fa-chevron-down text-gray-500 transition duration-150`,
                open && `-rotate-180`,
              )}
            />
          </button>
          {open && (
            <div className="p-4">
              {children}
              {mode === `create` && currentStep === index && (
                <div
                  className={cx(
                    `flex items-center mt-6`,
                    index === 1 ? `justify-end` : `justify-between`,
                  )}
                >
                  {index !== 1 && (
                    <Button
                      type="button"
                      onClick={() => {
                        setCurrentStep(currentStep - 1);
                        setOpen(false);
                      }}
                      color="secondary-white"
                      small
                    >
                      <i className="fa-solid fa-arrow-left mr-2" />
                      Back
                    </Button>
                  )}
                  <Button
                    type="button"
                    onClick={() => {
                      setCurrentStep(currentStep + 1);
                      setOpen(false);
                    }}
                    color="primary-violet"
                    small
                  >
                    Next <i className="fa-solid fa-arrow-right ml-2" />
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
