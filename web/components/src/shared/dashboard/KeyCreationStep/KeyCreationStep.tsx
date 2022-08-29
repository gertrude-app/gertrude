import React from 'react';
import cx from 'classnames';

type Props = {
  className?: string;
  title: React.ReactNode;
  children: React.ReactNode;
  currentStep: number;
  index: number; // starting from 1, to make it line up with the steps
  numSteps: number;
  stepName: string;
};

const KeyCreationStep: React.FC<Props> = ({
  className,
  title,
  currentStep,
  index,
  children,
  numSteps,
  stepName,
}) => (
  <div className={cx('flex items-stretch max-w-2xl', index > currentStep && 'h-16')}>
    <div className={cx(`w-12 flex justify-center items-center relative`)}>
      <div
        className={cx(
          'h-full border-r-2 border-dashed border-gray-300 absolute',
          index === 1 && 'h-1/2 bottom-0',
          index === numSteps && 'h-1/2 top-0',
        )}
      />
      <div
        className={cx(
          'relative w-4 h-4 rounded-full border-2',
          index < currentStep && 'border-indigo-500 bg-indigo-500',
          index === currentStep && 'border-indigo-500 bg-indigo-50',
          index > currentStep && 'border-gray-300 bg-gray-50',
        )}
      />
    </div>
    {index > currentStep ? (
      <h2 className="text-gray-500 text-lg flex items-center">{stepName}</h2>
    ) : (
      <div className="rounded-2xl shadow-lg p-4 flex-grow my-2 bg-white flex justify-between items-center border">
        {title}
        <i className="fa fa-chevron-down" />
      </div>
    )}
  </div>
);

export default KeyCreationStep;
