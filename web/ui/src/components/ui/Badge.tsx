import React from 'react';
import cx from 'clsx';
import type { LucideIcon } from 'lucide-react';

interface Props {
  children: React.ReactNode;
  color?: 'violet' | 'red' | 'green' | 'blue' | 'yellow' | 'neutral' | 'beta' | 'canary'; // defaults to neutral
  size?: 'xsmall' | 'small' | 'medium' | 'large'; // defaults to medium
  icon?: LucideIcon;
}

const Badge: React.FC<Props> = ({ children, color, size, icon: Icon }) => {
  const commonClasses = 'flex items-center select-none shrink-0';
  const colorClasses = cx({
    border: true,
    'bg-violet-100 border-violet-400 text-violet-900': color === 'violet',
    'bg-red-100 border-red-400 text-red-900': color === 'red',
    'bg-green-100 border-green-400 text-green-900': color === 'green',
    'bg-blue-100 border-blue-400 text-blue-900': color === 'blue',
    'bg-yellow-100 border-yellow-400 text-yellow-900': color === 'yellow',
    'bg-stone-100 border-stone-400 text-stone-800': color === 'neutral' || !color,
  });
  const sizeClasses = cx({
    'px-1 py-0 text-[10px] rounded-[5px] gap-1': size === 'xsmall',
    'px-1.5 py-0.25 text-xs rounded-[5px] gap-1': size === 'small',
    'px-2 py-0.25 text-sm rounded-[6px] gap-1.5': size === 'medium' || !size,
    'px-3 py-0.5 rounded-[7px] text-[15px] gap-2': size === 'large',
  });
  const iconSizeClasses = cx({
    'h-2.5 w-2.5': size === 'xsmall',
    'h-3 w-3': size === 'small',
    'h-3.5 w-3.5': size === 'medium' || !size,
    'h-4 w-4': size === 'large',
  });

  if (color === 'beta' || color === 'canary') {
    return (
      <div
        className={cx(
          'p-0.25',
          {
            'bg-gradient-to-br from-emerald-400 to-indigo-400': color === 'beta',
            'bg-gradient-to-br from-yellow-400 to-red-400': color === 'canary',
          },
          {
            'rounded-[6px]': size === 'small' || size === 'xsmall',
            'rounded-[7px]': size === 'medium' || !size,
            'rounded-[8px]': size === 'large',
          },
        )}
      >
        <div
          className={cx(commonClasses, sizeClasses, {
            'bg-gradient-to-br from-emerald-100 to-indigo-100': color === 'beta',
            'bg-gradient-to-br from-yellow-100 to-red-100': color === 'canary',
          })}
        >
          {Icon && (
            <Icon
              className={cx(iconSizeClasses, {
                'text-emerald-800': color === 'beta',
                'text-yellow-800': color === 'canary',
              })}
            />
          )}
          <span
            className={cx('text-transparent bg-clip-text bg-gradient-to-br', {
              'from-emerald-800 to-indigo-800': color === 'beta',
              'from-yellow-800 to-red-800': color === 'canary',
            })}
          >
            {children}
          </span>
        </div>
      </div>
    );
  }

  return (
    <div className={cx(commonClasses, colorClasses, sizeClasses)}>
      {Icon && <Icon className={iconSizeClasses} />}
      <span>{children}</span>
    </div>
  );
};

export default Badge;
