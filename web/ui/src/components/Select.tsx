import cx from 'clsx';
import { ChevronDownIcon } from 'lucide-react';
import React from 'react';
import Stack from '../primitives/Stack';
import Text from '../primitives/Text';
import DropdownMenu from './DropdownMenu';
import DropdownMenuItem, { type DropdownMenuItemIcon } from './DropdownMenuItem';

type NoInferValue<T> = [T][T extends unknown ? 0 : never];

export type SelectOption<Value extends string> =
  | Value
  | {
      value: Value;
      label: string;
      description?: React.ReactNode;
      icon?: DropdownMenuItemIcon;
    };
type SelectOptionValue<Option> = Option extends { value: infer Value extends string }
  ? Value
  : Option extends string
    ? Option
    : never;

type SelectSize = `small` | `medium`;
type SelectLabelPosition = `top` | `left`;

interface Props<Options extends readonly SelectOption<string>[]> {
  selected: NoInferValue<SelectOptionValue<Options[number]>>;
  setSelected: (selected: NoInferValue<SelectOptionValue<Options[number]>>) => void;
  possibleValues: Options;
  label?: string;
  labelPosition?: SelectLabelPosition;
  disabled?: boolean;
  size?: SelectSize;
  className?: string;
  open?: boolean;
  defaultOpen?: boolean;
  onOpenChange?: (open: boolean) => void;
}

const getOptionValue = <Value extends string>(option: SelectOption<Value>): Value =>
  typeof option === `string` ? option : option.value;

const getOptionLabel = <Value extends string>(option: SelectOption<Value>): string =>
  typeof option === `string` ? option : option.label;

const getOptionDescription = <Value extends string>(
  option: SelectOption<Value>,
): React.ReactNode => (typeof option === `string` ? undefined : option.description);

const getOptionIcon = <Value extends string>(
  option: SelectOption<Value>,
): DropdownMenuItemIcon | undefined =>
  typeof option === `string` ? undefined : option.icon;

const renderIcon = (
  icon: DropdownMenuItemIcon | undefined,
  className: string,
): React.ReactNode => {
  if (!icon) {
    return null;
  }

  if (React.isValidElement<{ className?: string }>(icon)) {
    return React.cloneElement(icon, {
      className: cx(className, icon.props.className),
    });
  }

  if (typeof icon === `function` || (typeof icon === `object` && `render` in icon)) {
    return React.createElement(icon as React.ElementType<{ className?: string }>, {
      className,
    });
  }

  return <span className={className}>{icon}</span>;
};

const Select = <const Options extends readonly SelectOption<string>[]>({
  selected,
  setSelected,
  possibleValues,
  label,
  labelPosition = `top`,
  disabled,
  size = `medium`,
  className,
  open,
  defaultOpen,
  onOpenChange,
}: Props<Options>): React.ReactElement => {
  const generatedId = React.useId();
  const selectedOption = possibleValues.find(
    (option) => getOptionValue(option) === selected,
  );
  const selectedLabel = selectedOption ? getOptionLabel(selectedOption) : selected;
  const SelectedIcon = selectedOption ? getOptionIcon(selectedOption) : undefined;

  return (
    <Stack
      direction={labelPosition === `left` ? `horizontal` : `vertical`}
      gap={labelPosition === `left` ? 2 : 1}
      align={labelPosition === `left` ? `center` : `stretch`}
      className={cx(disabled && `opacity-60`, className)}
    >
      {label && (
        <Text
          as="label"
          htmlFor={generatedId}
          variant="label"
          className={cx(
            labelPosition === `left` ? `shrink-0` : `ml-2.5`,
            disabled && `cursor-not-allowed`,
          )}
        >
          {label}
        </Text>
      )}
      <DropdownMenu
        disabled={disabled}
        open={open}
        defaultOpen={defaultOpen}
        onOpenChange={onOpenChange}
        trigger={
          <button
            id={generatedId}
            type="button"
            disabled={disabled}
            className={cx(
              `relative flex w-full items-stretch overflow-hidden border border-stone-300/80 bg-white text-left shadow shadow-stone-300/30 outline-none transition-[border-color,box-shadow] duration-150 select-none`,
              labelPosition === `left` && `min-w-0 flex-1`,
              size === `small`
                ? `min-h-[29.5px] rounded-[7px]`
                : `min-h-[36.5px] rounded-[9px]`,
              disabled
                ? `cursor-not-allowed bg-stone-100 shadow-none`
                : `cursor-pointer hover:border-stone-400/70 hover:shadow-stone-300/80 focus-visible:border-violet-300 focus-visible:shadow-violet-200/70 focus-visible:ring-2 focus-visible:ring-violet-200/70`,
            )}
          >
            <span
              className={cx(
                `flex min-w-0 flex-grow items-center`,
                size === `small`
                  ? `gap-1.5 px-2 py-1 text-[13px]`
                  : `gap-2 px-2.5 py-1.25 text-[15px]`,
                disabled ? `bg-stone-100 text-stone-500` : `bg-white text-stone-900`,
              )}
            >
              {renderIcon(
                SelectedIcon,
                cx(
                  `shrink-0 text-stone-500 mb-0.25`,
                  size === `small` ? `h-3 w-3` : `h-3.5 w-3.5`,
                ),
              )}
              <span className="truncate">{selectedLabel}</span>
            </span>
            <span
              className={cx(
                `flex shrink-0 items-center text-stone-400`,
                size === `small` ? `px-2` : `px-2.5`,
                disabled ? `bg-stone-100` : `bg-white`,
              )}
            >
              <ChevronDownIcon className={size === `small` ? `h-3 w-3` : `h-4 w-4`} />
            </span>
          </button>
        }
      >
        {possibleValues.map((option) => {
          const value = getOptionValue(option) as SelectOptionValue<Options[number]>;
          const optionLabel = getOptionLabel(option);
          const optionDescription = getOptionDescription(option);
          const OptionIcon = getOptionIcon(option);

          return (
            <DropdownMenuItem
              key={value}
              title={optionLabel}
              description={optionDescription}
              icon={OptionIcon}
              selected={value === selected}
              onSelect={() => setSelected(value)}
            />
          );
        })}
      </DropdownMenu>
    </Stack>
  );
};

export default Select;
