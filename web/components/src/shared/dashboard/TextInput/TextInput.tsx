import React, { useId, useState } from 'react';
import cx from 'classnames';
import Label from './Label';
import { isoToDateInput } from '../lib/dates';

type CommonProps = {
  label?: string;
  value: string;
  setValue(value: string): unknown;
  autoFocus?: boolean;
  required?: boolean;
  placeholder?: string;
  className?: string;
  disabled?: boolean;
};

type TextAreaProps = {
  rows?: number;
};

type InputProps = {
  unit?: string;
  prefix?: string;
};

type InputType = 'email' | 'text' | 'positiveInteger' | 'password' | 'date' | 'time';

type Props =
  | ({ type: InputType } & InputProps & CommonProps)
  | ({ type: 'textarea' } & TextAreaProps & CommonProps);

const TextInput: React.FC<Props> = ({
  label,
  value,
  setValue,
  required = false,
  autoFocus = false,
  placeholder,
  className,
  disabled,
  ...props
}) => {
  const [localValue, setLocalValue] = useState(value);
  const id = useId();
  const Element = isInput(props) ? `input` : `textarea`;
  return (
    <div className={cx(`flex flex-col space-y-1 w-full`, className)}>
      {label && <Label htmlFor={id}>{label}</Label>}
      <div className="flex shadow-sm rounded-lg">
        {isInput(props) && props.prefix && (
          <div className="flex justify-center items-center p-3 bg-gray-50 border border-r-0 rounded-l-lg">
            <h3 className="text-gray-500">{props.prefix}</h3>
          </div>
        )}
        <Element
          id={id}
          type={props.type === `positiveInteger` ? `number` : props.type}
          value={localValue}
          required={!!required}
          autoFocus={autoFocus}
          placeholder={placeholder}
          disabled={disabled}
          // all date inputs must be in the future (for now, at least)
          {...(props.type === `date`
            ? { min: isoToDateInput(new Date().toISOString()) }
            : {})}
          // textarea "rows"
          {...(isInput(props) ? {} : { rows: props.rows })}
          onChange={(e) => {
            const value = e.target.value;
            setLocalValue(value);
            if (props.type !== `positiveInteger` || isPositiveInteger(value)) {
              setValue(value);
            }
          }}
          className={`border border-gray-200 ring-0 ring-gray-200 outline-none py-3 px-4 focus:shadow-md transition duration-150 focus:border-indigo-500 focus:ring-indigo-500 focus:ring-1 text-gray-600 flex-grow z-10 w-12 ${
            isInput(props) && props.unit ? `rounded-r-none` : `rounded-r-lg`
          } ${isInput(props) && props.prefix ? `rounded-l-none` : `rounded-l-lg`}`}
        />
        {isInput(props) && props.unit && (
          <div className="flex justify-center items-center p-3 bg-gray-50 border border-l-0 rounded-r-lg">
            <h3 className="text-gray-500">{props.unit}</h3>
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

function isInput(props: { type: Props['type'] }): props is {
  type: InputType;
} & InputProps {
  return props.type !== `textarea`;
}
