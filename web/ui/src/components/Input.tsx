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
  size?: `small` | `medium`;
  label?: string;
  ariaLabel?: string;
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
  max?: number;
  step?: number;
  helperText?: string;
  error?: string;
  disabled?: boolean;
  className?: string;
};

const Input: React.FC<Props> = ({ ...props }) => {
  const small = props.size === `small`;
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
          className={cx(
            small ? `ml-2` : `ml-2.5`,
            props.disabled && `cursor-not-allowed`,
          )}
        >
          {props.label}
        </Text>
      )}
      <HStack
        align="stretch"
        className={cx(
          `relative overflow-hidden border border-stone-300/80 bg-white shadow shadow-stone-300/30 transition-[border-color,box-shadow] duration-150`,
          small ? `min-h-[28px] rounded-[7px]` : `min-h-[36.5px] rounded-[9px]`,
          props.disabled
            ? `cursor-not-allowed bg-stone-100 shadow-none`
            : props.error
              ? `border-red-300 focus-within:border-red-400 focus-within:shadow-red-200/70 focus-within:ring-2 focus-within:ring-red-200/70`
              : `focus-within:border-violet-300 focus-within:shadow-violet-200/70 focus-within:ring-2 focus-within:ring-violet-200/70`,
        )}
      >
        {props.prefix && (
          <>
            <span
              className={cx(
                `flex shrink-0 items-center bg-stone-50 text-stone-400 select-none`,
                small ? `px-2 text-xs` : `px-2.5 text-[15px]`,
              )}
            >
              {props.prefix}
            </span>
            <Divider orientation="vertical" className="!bg-stone-300/80" />
          </>
        )}
        <input
          id={id}
          name={props.name}
          className={cx(
            `min-w-0 flex-grow bg-white placeholder:text-stone-400/70 focus:outline-none`,
            small ? `px-2 py-0.75 text-xs` : `px-2.5 py-1.25`,
            props.type === `time` && `tabular-nums [color-scheme:light]`,
            props.disabled && `cursor-not-allowed bg-stone-100 text-stone-500`,
            props.button &&
              !props.suffix &&
              (props.button.label
                ? small
                  ? `pr-20`
                  : `pr-28`
                : small
                  ? `pr-9`
                  : `pr-12`),
          )}
          placeholder={props.placeholder}
          type={props.type}
          min={props.min}
          max={props.max}
          step={props.type === `time` ? 60 : props.step}
          value={props.value}
          disabled={props.disabled}
          required={props.required}
          autoComplete={props.autoComplete}
          aria-label={props.ariaLabel}
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
              `absolute inset-y-1 right-1 flex items-center gap-1.5 rounded-[4px] border border-stone-200 bg-stone-50 text-stone-600 shadow-sm shadow-stone-300/30 outline-none transition-[box-shadow,border-color] duration-100 select-none`,
              small ? `px-1.5` : `px-2.5`,
              props.disabled
                ? `cursor-not-allowed`
                : `cursor-pointer hover:border-stone-300 hover:shadow-stone-300/50 focus-visible:ring-2 focus-visible:ring-violet-300/80`,
            )}
          >
            {props.button.icon && (
              <Icon className={cx(`shrink-0`, small ? `h-3 w-3` : `h-4 w-4`)} />
            )}
            {props.button.label && (
              <span className={small ? `text-xs` : `text-sm`}>{props.button.label}</span>
            )}
          </button>
        )}
        {props.suffix && (
          <>
            <Divider orientation="vertical" className="!bg-stone-300/80" />
            <HStack
              gap={small ? 2 : 2.5}
              className={cx(
                `shrink-0 bg-stone-50`,
                small ? `pl-2` : `pl-2.5`,
                props.button ? `pr-1` : small ? `pr-2` : `pr-2.5`,
              )}
            >
              <span
                className={cx(
                  `text-stone-400 select-none`,
                  small ? `text-xs` : `text-[15px]`,
                )}
              >
                {props.suffix}
              </span>
              {props.button && (
                <button
                  type="button"
                  aria-label={props.button.ariaLabel}
                  disabled={props.disabled}
                  onClick={props.button.onClick}
                  className={cx(
                    `my-1 flex self-stretch items-center gap-1.5 rounded-[4px] border border-stone-200 bg-white text-stone-600 shadow-sm shadow-stone-300/30 outline-none transition-[box-shadow,border-color] duration-100 select-none`,
                    small ? `px-1.5` : `px-2.5`,
                    props.disabled
                      ? `cursor-not-allowed bg-stone-100`
                      : `cursor-pointer hover:border-stone-300 hover:shadow-stone-300/50 focus-visible:ring-2 focus-visible:ring-violet-300/80`,
                  )}
                >
                  {props.button.icon && (
                    <Icon className={cx(`shrink-0`, small ? `h-3 w-3` : `h-4 w-4`)} />
                  )}
                  {props.button.label && (
                    <span className={small ? `text-xs` : `text-sm`}>
                      {props.button.label}
                    </span>
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
          className={cx(
            `leading-5`,
            small ? `ml-2` : `ml-2.5`,
            !props.error && `font-normal`,
          )}
        >
          {props.error ?? props.helperText}
        </Text>
      )}
    </VStack>
  );
};

export default Input;
