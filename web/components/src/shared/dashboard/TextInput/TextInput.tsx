import React, { useId, useState } from 'react';
import cx from 'classnames';
import Label from './Label';

type Props = {
  type: 'email' | 'text' | 'positiveInteger' | 'password';
  label?: string;
  value: string;
  setValue(value: string): unknown;
  autoFocus?: boolean;
  required?: boolean;
  placeholder?: string;
  className?: string;
  unit?: string;
  disabled?: boolean;
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
  disabled,
  unit,
}) => {
  const [localValue, setLocalValue] = useState(value);
  const id = useId();
  return (
    <div className={cx(`flex flex-col w-full`, className)}>
      {label && <Label htmlFor={id}>{label}</Label>}
      <div className="flex shadow-sm rounded-lg">
        <input
          id={id}
          type={type === `positiveInteger` ? `number` : type}
          value={localValue}
          required={!!required}
          autoFocus={autoFocus}
          placeholder={placeholder}
          disabled={disabled}
          onChange={(e) => {
            const value = e.target.value;
            setLocalValue(value);
            if (type !== `positiveInteger` || isPositiveInteger(value)) {
              setValue(value);
            }
          }}
          className={`h-10 border ring-0 ring-gray-200 rounded-lg outline-none py-6 px-4 focus:shadow-md transition duration-150 focus:border-indigo-500 focus:ring-indigo-500 focus:ring-1 text-gray-600 flex-grow z-10 w-12 ${
            unit ? `rounded-r-none` : `rounded-r-lg`
          }`}
        />
        {unit && (
          <div className="flex justify-center items-center p-3 bg-gray-50 border border-l-0 rounded-r-lg">
            <h3 className="text-gray-500">{unit}</h3>
          </div>
        )}
      </div>
    </div>
  );
};

export default TextInput;

function isPositiveInteger(value: string): boolean {
  return (
    value.match(/^[0-9]+$/) !== null &&
    Number.isInteger(Number(value)) &&
    Number(value) >= 0
  );
}
