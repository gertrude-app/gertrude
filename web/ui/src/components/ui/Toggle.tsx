import React from 'react';
import cx from 'clsx';

interface Props {
  checked: boolean;
  setChecked: (checked: boolean) => void;
  disabled?: boolean;
}

const Toggle: React.FC<Props> = ({ checked, setChecked, disabled }) => {
  return (
    <button
      type="button"
      role="switch"
      aria-checked={checked}
      disabled={disabled}
      onClick={() => setChecked(!checked)}
      className={cx(
        'rounded-full w-12 h-5.5 relative cursor-pointer overflow-hidden outline-none focus-visible:ring-2 focus-visible:ring-violet-300/80 focus-visible:ring-offset-2 focus-visible:ring-offset-stone-50',
        disabled && '!cursor-not-allowed opacity-50',
      )}
    >
      <span
        className={cx(
          'w-36 h-5.5 absolute top-0 -left-12 flex transition-[translate] duration-400 ease-out',
          checked ? 'translate-x-12' : '-translate-x-12',
        )}
      >
        <span className="flex-grow bg-violet-500" />
        <span className="flex-grow bg-gradient-to-r from-violet-500 to-stone-200" />
        <span className="flex-grow bg-stone-200" />
      </span>
      <span
        className={cx(
          'absolute h-3.5 w-6 bg-white rounded-full top-1 left-1 shadow-sm transition-[translate,box-shadow] duration-150',
          checked ? 'translate-x-4 shadow-violet-700' : 'shadow-stone-300',
        )}
      />
    </button>
  );
};

export default Toggle;
