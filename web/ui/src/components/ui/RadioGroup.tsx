import React from 'react';
import cx from 'clsx';

interface Props {
  selected: string;
  setSelected: (selected: string) => void;
  possibleValues: string[];
  label?: string;
  disabled?: boolean;
  direction?: 'vertical' | 'horizontal';
  name?: string;
  ariaLabel?: string;
}

const RadioGroup: React.FC<Props> = ({
  selected,
  setSelected,
  possibleValues,
  label,
  disabled,
  direction = 'vertical',
  name,
  ariaLabel,
}) => {
  const generatedName = React.useId();
  const radioName = name ?? generatedName;

  return (
    <fieldset
      disabled={disabled}
      aria-label={!label ? ariaLabel : undefined}
      className={cx('flex flex-col gap-2', disabled && 'opacity-60')}
    >
      {label && <legend className="mb-1.5 text-[13px] text-stone-500">{label}</legend>}
      <div
        className={cx(
          'flex gap-3',
          direction === 'vertical' ? 'flex-col' : 'flex-row flex-wrap items-center',
        )}
      >
        {possibleValues.map((value, index) => {
          const id = `${generatedName}-${index}`;
          const checked = value === selected;

          return (
            <label
              key={value}
              htmlFor={id}
              className={cx(
                'inline-flex items-center gap-2.5 select-none',
                disabled ? 'cursor-not-allowed' : 'cursor-pointer',
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
              <span
                aria-hidden="true"
                className={cx(
                  'flex h-4.5 w-4.5 shrink-0 items-center justify-center rounded-full border bg-white shadow-sm transition-[border-color,box-shadow] duration-150 peer-focus-visible:ring-2 peer-focus-visible:ring-violet-300/80 peer-focus-visible:ring-offset-2 peer-focus-visible:ring-offset-stone-50',
                  checked
                    ? 'border-violet-800 shadow-violet-500/20'
                    : 'border-stone-300/80 shadow-stone-300/30',
                )}
              >
                <span
                  className={cx(
                    'h-2.25 w-2.25 rounded-full bg-violet-500 transition-[opacity,scale] duration-150',
                    checked ? 'scale-100 opacity-100' : 'scale-50 opacity-0',
                  )}
                />
              </span>
              <span className="text-sm font-medium text-stone-800">{value}</span>
            </label>
          );
        })}
      </div>
    </fieldset>
  );
};

export default RadioGroup;
