import cx from 'clsx';
import React from 'react';

interface Props {
  value: string;
  setValue: (value: string) => void;
  label?: string;
  placeholder?: string;
  id?: string;
  name?: string;
  rows?: number;
  required?: boolean;
  helperText?: string;
  error?: string;
  disabled?: boolean;
  resize?: `none` | `vertical` | `horizontal` | `both`;
}

const Textarea: React.FC<Props> = ({ ...props }) => {
  const generatedId = React.useId();
  const id = props.id ?? generatedId;
  const descriptionId = props.helperText || props.error ? `${id}-description` : undefined;

  return (
    <div className={cx(`flex flex-col gap-1`, props.disabled && `opacity-60`)}>
      {props.label && (
        <label
          htmlFor={id}
          className={cx(
            `ml-2.5 text-[13px] text-stone-500`,
            props.disabled && `cursor-not-allowed`,
          )}
        >
          {props.label}
        </label>
      )}
      <textarea
        id={id}
        name={props.name}
        rows={props.rows ?? 4}
        value={props.value}
        placeholder={props.placeholder}
        disabled={props.disabled}
        required={props.required}
        aria-invalid={props.error ? true : undefined}
        aria-describedby={descriptionId}
        onChange={(event) => props.setValue(event.target.value)}
        className={cx(
          `w-full rounded-[9px] border border-stone-300/80 bg-white px-2.5 py-1.5 text-[15px] leading-6 shadow shadow-stone-300/30 outline-none transition-[border-color,box-shadow] duration-150 placeholder:text-stone-400/70`,
          {
            'resize-none': props.resize === `none`,
            'resize-y': props.resize === `vertical` || props.resize === undefined,
            'resize-x': props.resize === `horizontal`,
            resize: props.resize === `both`,
          },
          props.disabled
            ? `cursor-not-allowed bg-stone-100 text-stone-500 shadow-none`
            : props.error
              ? `border-red-300 focus:border-red-400 focus:shadow-red-200/70 focus:ring-2 focus:ring-red-200/70`
              : `focus:border-violet-300 focus:shadow-violet-200/70 focus:ring-2 focus:ring-violet-200/70`,
        )}
      />
      {(props.error || props.helperText) && (
        <p
          id={descriptionId}
          className={cx(
            `ml-2.5 text-[13px] leading-5`,
            props.error ? `text-red-500` : `text-stone-500`,
          )}
        >
          {props.error ?? props.helperText}
        </p>
      )}
    </div>
  );
};

export default Textarea;
