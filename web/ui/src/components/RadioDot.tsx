import cx from 'clsx';
import React from 'react';
import HStack from '../primitives/HStack';

const RadioDot: React.FC<{ checked: boolean; className?: string }> = ({
  checked,
  className,
}) => (
  <HStack
    as="span"
    justify="center"
    aria-hidden="true"
    className={cx(
      `h-4.5 w-4.5 shrink-0 rounded-full border bg-white shadow-sm transition-[border-color,box-shadow] duration-150`,
      checked
        ? `border-violet-800 shadow-violet-500/20`
        : `border-stone-300/80 shadow-stone-300/30`,
      className,
    )}
  >
    <span
      className={cx(
        `h-2 w-2 rounded-full bg-violet-500 transition-[opacity,scale] duration-150`,
        checked ? `scale-100 opacity-100` : `scale-50 opacity-0`,
      )}
    />
  </HStack>
);

export default RadioDot;
