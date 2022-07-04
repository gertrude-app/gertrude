import React, { useId } from 'react';
import cx from 'classnames';

type Props = {
  type: 'email';
  label: string;
  value: string;
  setValue(value: string): unknown;
  autoFocus?: boolean;
  required?: boolean;
  placeholder?: string;
  className?: string;
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
}) => {
  const id = useId();
  return (
    <div className={cx(`flex flex-col space-y-1 w-full`, className)}>
      <label htmlFor={id} className="text-gray-500 text-lg">
        {label}
      </label>
      <input
        id={id}
        type={type}
        value={value}
        required={!!required}
        autoFocus={autoFocus}
        placeholder={placeholder}
        onChange={(e) => setValue(e.target.value)}
        className="h-10 border ring-0 ring-gray-200 rounded-lg shadow-sm outline-none py-6 px-4 focus:shadow-md transition duration-150 focus:border-indigo-500 focus:ring-indigo-500 focus:ring-1 text-gray-600"
      />
    </div>
  );
};

export default TextInput;
