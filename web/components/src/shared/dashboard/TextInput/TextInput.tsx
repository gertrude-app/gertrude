import React, { useId } from 'react';
import cx from 'classnames';

type Props = {
  type: 'email' | 'text';
  label: string;
  value: string;
  setValue(value: string): unknown;
  autoFocus?: boolean;
  required?: boolean;
  placeholder?: string;
  className?: string;
  unit?: string;
};

const TextInput: React.FC<Props> = ({
  type,
  label,
  value,
  setValue,
  required = false,
  autoFocus = false,
  placeholder,
  className,
  unit,
}) => {
  const id = useId();
  return (
    <div className={cx(`flex flex-col space-y-1 w-full`, className)}>
      <label htmlFor={id} className="text-gray-500 font-semibold text-md">
        {label}
      </label>
      <div className="flex">
        <input
          id={id}
          type={type}
          value={value}
          required={!!required}
          autoFocus={autoFocus}
          placeholder={placeholder}
          onChange={(e) => setValue(e.target.value)}
          className={`h-10 border ring-0 ring-gray-200 rounded-lg shadow-sm outline-none py-6 px-4 focus:shadow-md transition duration-150 focus:border-indigo-500 focus:ring-indigo-500 focus:ring-1 text-gray-600 flex-grow z-10 ${
            unit ? 'rounded-r-none' : 'rounded-r-lg'
          }`}
        />
        {unit && (
          <div className="flex justify-center items-center p-3 bg-gray-100 border border-l-0 rounded-r-lg">
            <h3 className="text-gray-600">{unit}</h3>
          </div>
        )}
      </div>
    </div>
  );
};

export default TextInput;
