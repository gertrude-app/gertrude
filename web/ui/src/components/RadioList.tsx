import cx from 'clsx';
import React from 'react';
import Text from '../primitives/Text';
import VStack from '../primitives/VStack';
import RadioDot from './RadioDot';

export interface RadioListOption {
  value: string;
  label: string;
  disabled?: boolean;
  disabledMessage?: string;
}

interface Props {
  options: RadioListOption[];
  selected?: string | null;
  onSelect: (value: string) => void;
  name?: string;
  ariaLabel?: string;
  ariaLabelledBy?: string;
  className?: string;
}

const RadioList: React.FC<Props> = ({
  options,
  selected,
  onSelect,
  name,
  ariaLabel,
  ariaLabelledBy,
  className,
}) => {
  const generatedName = React.useId();
  const radioName = name ?? generatedName;

  return (
    <VStack
      role="radiogroup"
      aria-label={ariaLabel}
      aria-labelledby={ariaLabelledBy}
      gap={1.5}
      className={className}
    >
      {options.map((option) => {
        const checked = option.value === selected;
        return (
          <label
            key={option.value}
            title={option.disabledMessage}
            className={cx(
              `flex min-h-10 items-center gap-2.5 rounded-lg border px-3 py-2 transition-colors select-none has-[:focus-visible]:ring-2 has-[:focus-visible]:ring-inset has-[:focus-visible]:ring-violet-300`,
              checked ? `border-violet-400 bg-violet-50` : `border-stone-200 bg-white`,
              option.disabled
                ? `cursor-not-allowed opacity-50`
                : `cursor-pointer hover:border-stone-300`,
            )}
          >
            <input
              type="radio"
              name={radioName}
              value={option.value}
              checked={checked}
              disabled={option.disabled}
              onChange={() => onSelect(option.value)}
              aria-label={
                option.disabledMessage
                  ? `${option.label}. ${option.disabledMessage}`
                  : undefined
              }
              className="sr-only"
            />
            <RadioDot checked={checked} />
            <Text as="span" variant="bodyStrong">
              {option.label}
            </Text>
          </label>
        );
      })}
    </VStack>
  );
};

export default RadioList;
