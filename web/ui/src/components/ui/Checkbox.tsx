import React from 'react';
import cx from 'clsx';
import { CheckIcon, MinusIcon } from 'lucide-react';

interface Props {
  checked: boolean;
  setChecked: (checked: boolean) => void;
  label?: string;
  description?: string;
  disabled?: boolean;
  indeterminate?: boolean;
  id?: string;
  name?: string;
  value?: string;
  ariaLabel?: string;
}

const Checkbox: React.FC<Props> = ({
  checked,
  setChecked,
  label,
  description,
  disabled,
  indeterminate,
  id,
  name,
  value,
  ariaLabel,
}) => {
  const generatedId = React.useId();
  const inputId = id ?? generatedId;
  const descriptionId = description ? `${inputId}-description` : undefined;
  const inputRef = React.useRef<HTMLInputElement>(null);

  React.useEffect(() => {
    if (inputRef.current) {
      inputRef.current.indeterminate = !!indeterminate;
    }
  }, [indeterminate]);

  return (
    <label
      htmlFor={inputId}
      className={cx(
        'inline-flex items-start gap-2.5 select-none',
        disabled ? 'cursor-not-allowed opacity-60' : 'cursor-pointer',
      )}
    >
      <input
        ref={inputRef}
        id={inputId}
        name={name}
        value={value}
        type="checkbox"
        checked={checked}
        disabled={disabled}
        aria-label={!label ? ariaLabel : undefined}
        aria-describedby={descriptionId}
        aria-checked={indeterminate ? 'mixed' : checked}
        onChange={(event) => setChecked(event.target.checked)}
        className="peer sr-only"
      />
      <span
        aria-hidden="true"
        className={cx(
          'mt-0.5 flex h-4.5 w-4.5 shrink-0 items-center justify-center rounded-[5px] border shadow-sm transition-[background-color,border-color,box-shadow] duration-150 peer-focus-visible:ring-2 peer-focus-visible:ring-violet-300/80 peer-focus-visible:ring-offset-2 peer-focus-visible:ring-offset-stone-50',
          checked || indeterminate
            ? 'border-violet-800 bg-violet-500 text-white shadow-violet-500/20'
            : 'border-stone-300/80 bg-white text-transparent shadow-stone-300/30',
        )}
      >
        {indeterminate ? (
          <MinusIcon className="h-3.5 w-3.5" strokeWidth={3.5} />
        ) : (
          <CheckIcon className="h-3.5 w-3.5" strokeWidth={3.5} />
        )}
      </span>
      {(label || description) && (
        <span className="flex min-w-0 translate-y-px flex-col">
          {label && <span className="text-sm font-medium text-stone-800">{label}</span>}
          {description && (
            <span id={descriptionId} className="text-xs leading-5 text-stone-500">
              {description}
            </span>
          )}
        </span>
      )}
    </label>
  );
};

export default Checkbox;
