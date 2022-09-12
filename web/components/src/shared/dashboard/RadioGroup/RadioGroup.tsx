import React from 'react';
import cx from 'classnames';
import { capitalize } from '../../lib/string';

type Props = {
  className?: string;
  options: string[];
  selectedOption: string;
  setSelectedOption(s: string): void;
};

const RadioGroup: React.FC<Props> = ({
  className,
  options,
  selectedOption,
  setSelectedOption,
}) => (
  <div className={cx(`space-y-0.5`, className)}>
    {options.map((option) => (
      <button
        className={cx(
          `flex items-center hover:bg-gray-50 w-full rounded-lg p-1.5 outline-none focus:ring-2 focus:ring-violet-300 transition duration:100 text-left leading-5`,
        )}
        onClick={() => setSelectedOption(option)}
      >
        <div
          className={cx(
            `w-4 h-4 border rounded-full mr-2 flex justify-center items-center transition duration:100`,
            selectedOption === option && `bg-violet-600 border-violet-600`,
          )}
        >
          <i className="fa-solid fa-circle fa-2xs text-white scale-75" />
        </div>
        <h3
          className={cx(
            selectedOption === option ? `font-medium text-gray-800` : `text-gray-600`,
          )}
        >
          {capitalize(option)}
        </h3>
      </button>
    ))}
  </div>
);

export default RadioGroup;
