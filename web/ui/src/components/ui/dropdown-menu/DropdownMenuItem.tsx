import React from 'react';
import cx from 'clsx';
import { Menu } from '@base-ui/react/menu';
import { CheckIcon, ChevronRightIcon, type LucideIcon } from 'lucide-react';

interface Props {
  title: string;
  icon?: LucideIcon;
  selected?: boolean;
  active?: boolean;
  onSelect?: () => void;
  children?: React.ReactNode; // for sub-menus
}

const itemClasses = (active?: boolean): string =>
  cx(
    'flex justify-between items-center cursor-pointer outline-none hover:bg-stone-100 data-[highlighted]:bg-stone-100 px-2 py-1 rounded-lg',
    active && 'bg-stone-100',
  );

const DropdownMenuItem: React.FC<Props> = ({
  title,
  icon: Icon,
  selected,
  active,
  onSelect,
  children,
}) => {
  const content = (
    <>
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
      {selected && !children && (
        <div className="w-4 h-4 rounded-full flex justify-center items-center bg-violet-500">
          <CheckIcon
            className="w-3 h-3 text-white translate-y-[0.5px]"
            strokeWidth={3.5}
          />
        </div>
      )}
    </>
  );

  if (children) {
    return (
      <Menu.SubmenuRoot>
        <Menu.SubmenuTrigger className={itemClasses(active)}>
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
        </Menu.SubmenuTrigger>
        <Menu.Portal>
          <Menu.Positioner sideOffset={4} alignOffset={-4} className="z-[60]">
            <Menu.Popup className="z-[60] bg-white shadow-md shadow-stone-300/50 p-1 rounded-xl border border-stone-200 w-60 flex flex-col gap-1 mx-0 -mt-1 outline-none">
              {children}
            </Menu.Popup>
          </Menu.Positioner>
        </Menu.Portal>
      </Menu.SubmenuRoot>
    );
  }

  return (
    <Menu.Item onClick={() => onSelect?.()} className={itemClasses(active)}>
      {content}
    </Menu.Item>
  );
};

export default DropdownMenuItem;
