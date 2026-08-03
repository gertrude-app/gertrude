import cx from 'clsx';
import React from 'react';

interface Props {
  checked: boolean;
  setChecked: (checked: boolean) => void;
  disabled?: boolean;
  small?: boolean;
  ariaLabel?: string;
}

const Toggle: React.FC<Props> = ({ checked, setChecked, disabled, small, ariaLabel }) => (
  <button
    type="button"
    role="switch"
    aria-checked={checked}
    aria-label={ariaLabel}
    disabled={disabled}
    onClick={() => setChecked(!checked)}
    className={cx(
      `rounded-full relative cursor-pointer overflow-hidden outline-none focus-visible:ring-2 focus-visible:ring-violet-300/80 focus-visible:ring-offset-2 focus-visible:ring-offset-stone-50 shrink-0`,
      small ? `w-8 h-4` : `w-12 h-5.5`,
      disabled && `!cursor-not-allowed opacity-50`,
    )}
  >
    <span
      className={cx(
        `w-36 h-5.5 absolute top-0 -left-12 flex transition-[translate] duration-400 ease-out`,
        checked ? `translate-x-12` : `-translate-x-12`,
      )}
    >
      <span className="flex-grow bg-violet-500" />
      <span className="flex-grow bg-gradient-to-r from-violet-500 to-stone-200" />
      <span className="flex-grow bg-stone-200" />
    </span>
    <span
      className={cx(
        `absolute bg-white rounded-full shadow-sm transition-[translate,box-shadow] duration-150`,
        small ? `h-2.75 w-4 top-[2.5px] left-[3px]` : `h-3.5 w-6 top-1 left-1`,
        checked
          ? small
            ? `translate-x-[10px] shadow-violet-700`
            : `translate-x-4 shadow-violet-700`
          : `shadow-stone-300`,
      )}
    />
  </button>
);

export default Toggle;
