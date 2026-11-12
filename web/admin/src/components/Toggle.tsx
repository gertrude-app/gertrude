import React from 'react';

interface Props {
  checked: boolean;
  onChange: (checked: boolean) => void;
  label: string;
  color?: `emerald` | `violet`;
  labelPosition?: `before` | `after`;
  className?: string;
}

const Toggle: React.FC<Props> = ({
  checked,
  onChange,
  label,
  color = `violet`,
  labelPosition = `after`,
  className = ``,
}) => (
  <button
    type="button"
    role="switch"
    aria-checked={checked}
    onClick={() => onChange(!checked)}
    className={`inline-flex items-center gap-2.5 rounded-lg px-2 py-1.5 text-xs sm:text-sm font-medium text-slate-500 hover:text-slate-700 hover:bg-slate-50 transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-offset-2 ${
      color === `emerald`
        ? `focus-visible:ring-emerald-500`
        : `focus-visible:ring-brand-violet`
    } ${className}`}
  >
    {labelPosition === `before` && label}
    <span
      aria-hidden="true"
      className={`inline-flex h-5 w-9 shrink-0 items-center rounded-full p-0.5 transition-colors ${
        checked
          ? color === `emerald`
            ? `bg-emerald-500`
            : `bg-brand-violet`
          : `bg-slate-200`
      }`}
    >
      <span
        className={`h-4 w-4 rounded-full bg-white shadow-sm transition-transform ${
          checked ? `translate-x-4` : `translate-x-0`
        }`}
      />
    </span>
    {labelPosition === `after` && label}
  </button>
);

export default Toggle;
