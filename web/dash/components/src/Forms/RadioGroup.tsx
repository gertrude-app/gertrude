import React from 'react';
import cx from 'classnames';
import { capitalize } from '@shared/string';

type Props<Value extends string> = {
  className?: string;
  options: Array<{ value: Value; display: string }>;
  selectedOption: Value;
  setSelectedOption(selected: Value): void;
};

function RadioGroup<Value extends string = string>({
  className,
  options,
  selectedOption,
  setSelectedOption,
}: Parameters<React.FC<Props<Value>>>[0]): ReturnType<React.FC<Props<Value>>> {
  return (
    <div className={cx(`space-y-0.5`, className)}>
      {options.map(({ value, display }) => (
        <button
          key={value}
          className={cx(
            `flex items-center hover:bg-gray-50 w-full rounded-lg p-1.5 outline-none focus:ring-2 focus:ring-violet-300 transition duration:100 text-left leading-5`,
          )}
          onClick={() => setSelectedOption(value)}
        >
          <div
            className={cx(
              `w-4 h-4 border rounded-full mr-2 flex justify-center items-center transition duration:100`,
              selectedOption === value && `bg-violet-600 border-violet-600`,
            )}
          >
            <i className="fa-solid fa-circle fa-2xs text-white scale-75" />
          </div>
          <h3
            className={cx(
              selectedOption === value ? `font-medium text-gray-800` : `text-gray-600`,
            )}
          >
            {capitalize(display)}
          </h3>
        </button>
      ))}
    </div>
  );
}

export default RadioGroup;
