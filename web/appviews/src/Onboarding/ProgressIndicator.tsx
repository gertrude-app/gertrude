import React from 'react';
import cx from 'classnames';

interface Props {
  step: number;
}

const ProgressIndicator: React.FC<Props> = ({ step }) => (
  <div className="flex gap-8 relative items-center">
    <div
      className={cx(
        `absolute h-[3px] bg-violet-300 transition-[width] duration-1000 rounded-full`,
      )}
      style={{
        width: `calc(${((step - 1) * 100) / 6}%)`,
      }}
    />
    {new Array(7).fill(null).map((_, i) => (
      <Step
        key={i} // fine in this context
        number={i + 1}
        status={step < i + 1 ? `incomplete` : step > i + 1 ? `complete` : `current`}
      />
    ))}
  </div>
);

export default ProgressIndicator;

interface StepProps {
  number: number;
  status: 'complete' | 'current' | 'incomplete';
}

const Step: React.FC<StepProps> = ({ status }) => (
  <div
    className={cx(
      `border-2 w-3.5 h-3.5 rounded-full flex justify-center items-center font-bold text-lg relative transition-[background-color,border-color,color] duration-700 delay-500`,
      {
        'border-violet-500 bg-violet-500': status === `current`,
        'border-violet-300 bg-violet-200': status === `complete`,
        'border-[#eceff7] bg-[#eceff7]': status === `incomplete`,
      },
    )}
  />
);
