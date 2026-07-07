import cx from 'clsx';
import React from 'react';
import HStack from '../primitives/HStack';
import Stack from '../primitives/Stack';
import Text from '../primitives/Text';
import VStack from '../primitives/VStack';

interface Props {
  selected: string;
  setSelected: (selected: string) => void;
  possibleValues: string[];
  label?: string;
  disabled?: boolean;
  direction?: `vertical` | `horizontal`;
  name?: string;
  ariaLabel?: string;
}

const RadioGroup: React.FC<Props> = ({
  selected,
  setSelected,
  possibleValues,
  label,
  disabled,
  direction = `vertical`,
  name,
  ariaLabel,
}) => {
  const generatedName = React.useId();
  const radioName = name ?? generatedName;

  return (
    <VStack
      as="fieldset"
      gap={2}
      disabled={disabled}
      aria-label={!label ? ariaLabel : undefined}
      className={cx(disabled && `opacity-60`)}
    >
      {label && (
        <Text as="legend" variant="label" className="mb-1.5 font-normal">
          {label}
        </Text>
      )}
      <Stack
        direction={direction === `vertical` ? `vertical` : `horizontal`}
        gap={3}
        align={direction === `vertical` ? `stretch` : `center`}
        wrap={direction === `horizontal`}
      >
        {possibleValues.map((value, index) => {
          const id = `${generatedName}-${index}`;
          const checked = value === selected;

          return (
            <label
              key={value}
              htmlFor={id}
              className={cx(
                `inline-flex items-center gap-2.5 select-none`,
                disabled ? `cursor-not-allowed` : `cursor-pointer`,
              )}
            >
              <input
                id={id}
                type="radio"
                name={radioName}
                value={value}
                checked={checked}
                disabled={disabled}
                onChange={() => setSelected(value)}
                className="peer sr-only"
              />
              <HStack
                as="span"
                justify="center"
                aria-hidden="true"
                className={cx(
                  `h-4.5 w-4.5 shrink-0 rounded-full border bg-white shadow-sm transition-[border-color,box-shadow] duration-150 peer-focus-visible:ring-2 peer-focus-visible:ring-violet-300/80 peer-focus-visible:ring-offset-2 peer-focus-visible:ring-offset-stone-50`,
                  checked
                    ? `border-violet-800 shadow-violet-500/20`
                    : `border-stone-300/80 shadow-stone-300/30`,
                )}
              >
                <span
                  className={cx(
                    `h-2.25 w-2.25 rounded-full bg-violet-500 transition-[opacity,scale] duration-150`,
                    checked ? `scale-100 opacity-100` : `scale-50 opacity-0`,
                  )}
                />
              </HStack>
              <Text variant="bodyStrong">{value}</Text>
            </label>
          );
        })}
      </Stack>
    </VStack>
  );
};

export default RadioGroup;
