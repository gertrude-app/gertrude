import React from 'react';
import cx from 'clsx';
import type { LucideIcon } from 'lucide-react';

interface Props {
  children: React.ReactNode;
  color?: 'violet' | 'red' | 'green' | 'blue' | 'yellow' | 'neutral'; // defaults to neutral
  size?: 'small' | 'medium' | 'large'; // defaults to medium
  icon?: LucideIcon;
}

const Badge: React.FC<Props> = ({ children, color, size, icon: Icon }) => {
  const classes = cx(
    'border flex items-center select-none',
    {
      'bg-violet-100 border-violet-400 text-violet-900': color === 'violet',
      'bg-red-100 border-red-400 text-red-900': color === 'red',
      'bg-green-100 border-green-400 text-green-900': color === 'green',
      'bg-blue-100 border-blue-400 text-blue-900': color === 'blue',
      'bg-yellow-100 border-yellow-400 text-yellow-900': color === 'yellow',
      'bg-stone-100 border-stone-400 text-stone-800': color === 'neutral' || !color,
    },
    {
      'px-1.5 py-0.25 text-xs rounded-[5px] gap-1': size === 'small',
      'px-2 py-0.25 text-sm rounded-[6px] gap-1.5': size === 'medium' || !size,
      'px-3 py-0.5 rounded-[7px] text-[15px] gap-2': size === 'large',
    },
  );
  const iconSizeClasses = cx({
    'h-3 w-3': size === 'small',
    'h-3.5 w-3.5': size === 'medium' || !size,
    'h-4 w-4': size === 'large',
  });

  return (
    <div className={classes}>
      {Icon && <Icon className={iconSizeClasses} />}
      <span>{children}</span>
    </div>
  );
};

export default Badge;
