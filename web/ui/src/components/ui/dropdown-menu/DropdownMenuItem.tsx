import React from 'react';
import cx from 'clsx';
import * as DM from '@radix-ui/react-dropdown-menu';
import { CheckIcon, ChevronRightIcon, type LucideIcon } from 'lucide-react';

interface Props {
  title: string;
  icon?: LucideIcon;
  selected?: boolean;
  active?: boolean;
  onSelect?: () => void;
  children?: React.ReactNode; // for sub-menus
}

const DropdownMenuItem: React.FC<Props> = ({
  title,
  icon: Icon,
  selected,
  active,
  onSelect,
  children,
}) => {
  if (children) {
    return (
      <DM.Sub>
        <DM.SubTrigger
          className={cx(
            'flex justify-between items-center cursor-pointer outline-none hover:bg-stone-100 data-[highlighted]:bg-stone-100 px-2 py-1 rounded-lg',
            active && 'bg-stone-100',
          )}
        >
          <div className="flex items-center gap-2">
            {Icon && (
              <Icon
                className={cx(
                  'w-3.5 h-3.5',
                  selected ? 'text-violet-800' : 'text-stone-500',
                )}
              />
            )}
            <span className={cx(selected ? 'text-violet-800' : 'text-stone-800')}>
              {title}
            </span>
          </div>
          <ChevronRightIcon className="w-4 h-4 text-stone-500" />
        </DM.SubTrigger>
        <DM.Portal>
          <DM.SubContent className="bg-white shadow-md shadow-stone-300/50 p-1 rounded-xl border border-stone-200 w-60 flex flex-col gap-1 mx-0 -mt-1">
            {children}
          </DM.SubContent>
        </DM.Portal>
      </DM.Sub>
    );
  }

  return (
    <DM.Item
      onSelect={() => onSelect?.()}
      className={cx(
        'flex justify-between items-center cursor-pointer outline-none hover:bg-stone-100 data-[highlighted]:bg-stone-100 px-2 py-1 rounded-lg',
        active && 'bg-stone-100',
      )}
    >
      <div className="flex items-center gap-2">
        {Icon && (
          <Icon
            className={cx('w-3.5 h-3.5', selected ? 'text-violet-800' : 'text-stone-500')}
          />
        )}
        <span className={cx(selected ? 'text-violet-800' : 'text-stone-800')}>
          {title}
        </span>
      </div>
      {selected && (
        <div className="w-4 h-4 rounded-full flex justify-center items-center bg-violet-500">
          <CheckIcon
            className="w-3 h-3 text-white translate-y-[0.5px]"
            strokeWidth={3.5}
          />
        </div>
      )}
    </DM.Item>
  );
};

export default DropdownMenuItem;
