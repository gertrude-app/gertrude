'use client';

import cx from 'classnames';
import React, { useEffect, useRef } from 'react';

interface Props {
  value: string;
  onChange: (value: string) => void;
  onSubmit?: () => void;
  disabled?: boolean;
  length?: number;
  className?: string;
  autoFocus?: boolean;
}

const CodeInput: React.FC<Props> = ({
  value,
  onChange,
  onSubmit,
  disabled = false,
  length = 6,
  className,
  autoFocus = true,
}) => {
  const inputRef = useRef<HTMLInputElement>(null);

  useEffect(() => {
    if (autoFocus) {
      inputRef.current?.focus({ preventScroll: true });
    }
  }, [autoFocus]);

  const handleChange = (e: React.ChangeEvent<HTMLInputElement>): void => {
    const digits = e.target.value.replace(/\D/g, ``).slice(0, length);
    onChange(digits);
  };

  const handleKeyDown = (e: React.KeyboardEvent<HTMLInputElement>): void => {
    if (e.key === `Enter` && value.length === length && onSubmit && !disabled) {
      onSubmit();
    }
  };

  const handlePaste = (e: React.ClipboardEvent<HTMLInputElement>): void => {
    e.preventDefault();
    const pasted = e.clipboardData.getData(`text`).replace(/\D/g, ``).slice(0, length);
    onChange(pasted);
  };

  return (
    <input
      ref={inputRef}
      type="text"
      inputMode="numeric"
      autoComplete="one-time-code"
      value={value}
      onChange={handleChange}
      onKeyDown={handleKeyDown}
      onPaste={handlePaste}
      disabled={disabled}
      placeholder={`*`.repeat(length)}
      className={cx(
        `rounded-2xl text-3xl px-6 py-4 font-bold font-mono tracking-[8px] border-2 text-center`,
        `transition-[border-color,transform,box-shadow] duration-300`,
        `outline-none focus:ring-0 focus:-translate-y-0.5`,
        disabled
          ? `border-slate-200 bg-slate-50 text-slate-400 cursor-not-allowed`
          : `border-slate-200 text-slate-600 focus:border-violet-400 shadow-lg shadow-slate-300/50 focus:shadow-xl focus:shadow-slate-300/50 placeholder:text-slate-200`,
        className,
      )}
    />
  );
};

export default CodeInput;
