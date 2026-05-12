import React from 'react';
import cx from 'clsx';
import { ArrowRightIcon, type LucideIcon } from 'lucide-react';

type Props = {
  type: 'text' | 'password' | 'email' | 'number';
  value: string;
  setValue: (value: string) => void;
  label?: string;
  placeholder?: string;
  prefix?: string;
  suffix?: string;
  button?: {
    label?: string;
    ariaLabel?: string;
    icon?: LucideIcon;
    onClick: () => void;
  };
  id?: string;
  name?: string;
  required?: boolean;
  autoComplete?: string;
  helperText?: string;
  error?: string;
  disabled?: boolean;
};

const Input: React.FC<Props> = ({ ...props }) => {
  const Icon = props.button?.icon || ArrowRightIcon;
  const generatedId = React.useId();
  const id = props.id ?? generatedId;
  const descriptionId = props.helperText || props.error ? `${id}-description` : undefined;

  return (
    <div className={cx('flex flex-col gap-0.5', props.disabled && 'opacity-60')}>
      {props.label && (
        <label
          htmlFor={id}
          className={cx(
            'ml-2.25 text-xs text-stone-500',
            props.disabled && 'cursor-not-allowed',
          )}
        >
          {props.label}
        </label>
      )}
      <div
        className={cx(
          'relative flex min-h-9 items-stretch overflow-hidden rounded-lg border border-stone-300/80 bg-white shadow shadow-stone-300/30 transition-[border-color,box-shadow] duration-150',
          props.disabled
            ? 'cursor-not-allowed bg-stone-100 shadow-none'
            : props.error
              ? 'border-red-300 focus-within:border-red-400 focus-within:shadow-red-200/70 focus-within:ring-2 focus-within:ring-red-200/70'
              : 'focus-within:border-violet-300 focus-within:shadow-violet-200/70 focus-within:ring-2 focus-within:ring-violet-200/70',
        )}
      >
        {props.prefix && (
          <span className="flex shrink-0 items-center border-r border-stone-300/80 bg-stone-50 px-2 text-sm text-stone-400">
            {props.prefix}
          </span>
        )}
        <input
          id={id}
          name={props.name}
          className={cx(
            'min-w-0 flex-grow bg-white px-2 py-1 placeholder:text-stone-400/70 focus:outline-none',
            props.disabled && 'cursor-not-allowed bg-stone-100 text-stone-500',
            props.button && !props.suffix && (props.button.label ? 'pr-24' : 'pr-11'),
          )}
          placeholder={props.placeholder}
          type={props.type}
          value={props.value}
          disabled={props.disabled}
          required={props.required}
          autoComplete={props.autoComplete}
          aria-invalid={props.error ? true : undefined}
          aria-describedby={descriptionId}
          onChange={(e) => props.setValue(e.target.value)}
        />
        {props.button && !props.suffix && (
          <button
            type="button"
            aria-label={props.button.ariaLabel}
            disabled={props.disabled}
            onClick={props.button.onClick}
            className={cx(
              'absolute right-1 top-1/2 flex h-[calc(100%-8px)] -translate-y-1/2 items-center gap-1 rounded border border-stone-200 bg-stone-50 px-2 text-stone-600 shadow-sm shadow-stone-300/30 outline-none transition-[box-shadow,border-color] duration-100',
              props.disabled
                ? 'cursor-not-allowed'
                : 'cursor-pointer hover:border-stone-300 hover:shadow-stone-300/50 focus-visible:ring-2 focus-visible:ring-violet-300/80',
            )}
          >
            {props.button.icon && <Icon className="h-3.5 w-3.5 shrink-0" />}
            {props.button.label && <span className="text-sm">{props.button.label}</span>}
          </button>
        )}
        {props.suffix && (
          <div
            className={cx(
              'flex shrink-0 items-center gap-2 border-l border-stone-300/80 bg-stone-50 pl-2',
              props.button ? 'pr-1' : 'pr-2',
            )}
          >
            <span className="text-sm text-stone-400">{props.suffix}</span>
            {props.button && (
              <button
                type="button"
                aria-label={props.button.ariaLabel}
                disabled={props.disabled}
                onClick={props.button.onClick}
                className={cx(
                  'flex h-7 items-center gap-1 rounded border border-stone-200 bg-white px-2 text-stone-600 shadow-sm shadow-stone-300/30 outline-none transition-[box-shadow,border-color] duration-100',
                  props.disabled
                    ? 'cursor-not-allowed bg-stone-100'
                    : 'cursor-pointer hover:border-stone-300 hover:shadow-stone-300/50 focus-visible:ring-2 focus-visible:ring-violet-300/80',
                )}
              >
                {props.button.icon && <Icon className="h-3.5 w-3.5 shrink-0" />}
                {props.button.label && (
                  <span className="text-sm">{props.button.label}</span>
                )}
              </button>
            )}
          </div>
        )}
      </div>
      {(props.error || props.helperText) && (
        <p
          id={descriptionId}
          className={cx(
            'ml-2.25 text-xs leading-5',
            props.error ? 'text-red-500' : 'text-stone-500',
          )}
        >
          {props.error ?? props.helperText}
        </p>
      )}
    </div>
  );
};

export default Input;
