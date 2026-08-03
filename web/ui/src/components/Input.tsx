import cx from 'clsx';
import { ArrowRightIcon, type LucideIcon } from 'lucide-react';
import React from 'react';
import Divider from '../primitives/Divider';
import HStack from '../primitives/HStack';
import Text from '../primitives/Text';
import VStack from '../primitives/VStack';

type Props = {
  type: `text` | `password` | `email` | `number` | `time`;
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
  min?: number;
  step?: number;
  helperText?: string;
  error?: string;
  disabled?: boolean;
  className?: string;
};

const Input: React.FC<Props> = ({ ...props }) => {
  const Icon = props.button?.icon || ArrowRightIcon;
  const generatedId = React.useId();
  const id = props.id ?? generatedId;
  const descriptionId = props.helperText || props.error ? `${id}-description` : undefined;

  return (
    <VStack gap={1} className={cx(props.disabled && `opacity-60`, props.className)}>
      {props.label && (
        <Text
          as="label"
          htmlFor={id}
          variant="label"
          className={cx(`ml-2.5`, props.disabled && `cursor-not-allowed`)}
        >
          {props.label}
        </Text>
      )}
      <HStack
        align="stretch"
        className={cx(
          `relative min-h-[36.5px] overflow-hidden rounded-[9px] border border-stone-300/80 bg-white shadow shadow-stone-300/30 transition-[border-color,box-shadow] duration-150`,
          props.disabled
            ? `cursor-not-allowed bg-stone-100 shadow-none`
            : props.error
              ? `border-red-300 focus-within:border-red-400 focus-within:shadow-red-200/70 focus-within:ring-2 focus-within:ring-red-200/70`
              : `focus-within:border-violet-300 focus-within:shadow-violet-200/70 focus-within:ring-2 focus-within:ring-violet-200/70`,
        )}
      >
        {props.prefix && (
          <>
            <span className="flex shrink-0 items-center bg-stone-50 px-2.5 text-[15px] text-stone-400 select-none">
              {props.prefix}
            </span>
            <Divider orientation="vertical" className="!bg-stone-300/80" />
          </>
        )}
        <input
          id={id}
          name={props.name}
          className={cx(
            `min-w-0 flex-grow bg-white px-2.5 py-1.25 placeholder:text-stone-400/70 focus:outline-none`,
            props.type === `time` && `tabular-nums [color-scheme:light]`,
            props.disabled && `cursor-not-allowed bg-stone-100 text-stone-500`,
            props.button && !props.suffix && (props.button.label ? `pr-28` : `pr-12`),
          )}
          placeholder={props.placeholder}
          type={props.type}
          min={props.min}
          step={props.type === `time` ? 60 : props.step}
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
              `absolute inset-y-1 right-1 flex items-center gap-1.5 rounded-[4px] border border-stone-200 bg-stone-50 px-2.5 text-stone-600 shadow-sm shadow-stone-300/30 outline-none transition-[box-shadow,border-color] duration-100 select-none`,
              props.disabled
                ? `cursor-not-allowed`
                : `cursor-pointer hover:border-stone-300 hover:shadow-stone-300/50 focus-visible:ring-2 focus-visible:ring-violet-300/80`,
            )}
          >
            {props.button.icon && <Icon className="h-4 w-4 shrink-0" />}
            {props.button.label && <span className="text-sm">{props.button.label}</span>}
          </button>
        )}
        {props.suffix && (
          <>
            <Divider orientation="vertical" className="!bg-stone-300/80" />
            <HStack
              gap={2.5}
              className={cx(
                `shrink-0 bg-stone-50 pl-2.5`,
                props.button ? `pr-1` : `pr-2.5`,
              )}
            >
              <span className="text-[15px] text-stone-400 select-none">
                {props.suffix}
              </span>
              {props.button && (
                <button
                  type="button"
                  aria-label={props.button.ariaLabel}
                  disabled={props.disabled}
                  onClick={props.button.onClick}
                  className={cx(
                    `my-1 flex self-stretch items-center gap-1.5 rounded-[4px] border border-stone-200 bg-white px-2.5 text-stone-600 shadow-sm shadow-stone-300/30 outline-none transition-[box-shadow,border-color] duration-100 select-none`,
                    props.disabled
                      ? `cursor-not-allowed bg-stone-100`
                      : `cursor-pointer hover:border-stone-300 hover:shadow-stone-300/50 focus-visible:ring-2 focus-visible:ring-violet-300/80`,
                  )}
                >
                  {props.button.icon && <Icon className="h-4 w-4 shrink-0" />}
                  {props.button.label && (
                    <span className="text-sm">{props.button.label}</span>
                  )}
                </button>
              )}
            </HStack>
          </>
        )}
      </HStack>
      {(props.error || props.helperText) && (
        <Text
          as="p"
          id={descriptionId}
          variant={props.error ? `error` : `label`}
          className={cx(`ml-2.5 leading-5`, !props.error && `font-normal`)}
        >
          {props.error ?? props.helperText}
        </Text>
      )}
    </VStack>
  );
};

export default Input;
