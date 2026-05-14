import React from 'react';
import cx from 'clsx';
import { ChevronDownIcon } from 'lucide-react';
import DropdownMenu from './dropdown-menu/DropdownMenu';
import DropdownMenuItem from './dropdown-menu/DropdownMenuItem';

interface Props {
  selected: string;
  setSelected: (selected: string) => void;
  possibleValues: string[];
  label?: string;
  disabled?: boolean;
}

const Select: React.FC<Props> = ({
  selected,
  setSelected,
  possibleValues,
  label,
  disabled,
}) => {
  const generatedId = React.useId();

  return (
    <div className={cx('flex flex-col gap-1', disabled && 'opacity-60')}>
      {label && (
        <label
          htmlFor={generatedId}
          className={cx(
            'ml-2.5 text-[13px] text-stone-500',
            disabled && 'cursor-not-allowed',
          )}
        >
          {label}
        </label>
      )}
      <DropdownMenu
        disabled={disabled}
        trigger={
          <button
            id={generatedId}
            type="button"
            disabled={disabled}
            className={cx(
              'relative flex min-h-[36.5px] w-full items-stretch overflow-hidden rounded-[9px] border border-stone-300/80 bg-white text-left shadow shadow-stone-300/30 outline-none transition-[border-color,box-shadow] duration-150 select-none',
              disabled
                ? 'cursor-not-allowed bg-stone-100 shadow-none'
                : 'cursor-pointer focus-visible:border-violet-300 focus-visible:shadow-violet-200/70 focus-visible:ring-2 focus-visible:ring-violet-200/70',
            )}
          >
            <span
              className={cx(
                'flex min-w-0 flex-grow items-center truncate px-2.5 py-1.25 text-[15px]',
                disabled ? 'bg-stone-100 text-stone-500' : 'bg-white text-stone-900',
              )}
            >
              {selected}
            </span>
            <span
              className={cx(
                'flex shrink-0 items-center px-2.5 text-stone-400',
                disabled ? 'bg-stone-100' : 'bg-white',
              )}
            >
              <ChevronDownIcon className="h-4 w-4" />
            </span>
          </button>
        }
      >
        {possibleValues.map((value) => (
          <DropdownMenuItem
            key={value}
            title={value}
            selected={value === selected}
            onSelect={() => setSelected(value)}
          />
        ))}
      </DropdownMenu>
    </div>
  );
};

export default Select;
