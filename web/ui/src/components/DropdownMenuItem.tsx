import { Menu } from '@base-ui/react/menu';
import cx from 'clsx';
import { CheckIcon, ChevronRightIcon, type LucideIcon } from 'lucide-react';
import React from 'react';
import HStack from '../primitives/HStack';
import Text from '../primitives/Text';
import VStack from '../primitives/VStack';
import { useOverlayPortalContainer } from './OverlayPortalContext';

export type DropdownMenuItemIcon = LucideIcon | React.ReactNode;

interface Props {
  title: string;
  description?: React.ReactNode;
  icon?: DropdownMenuItemIcon;
  selected?: boolean;
  active?: boolean;
  onSelect?: () => void;
  children?: React.ReactNode;
  destructive?: boolean;
  open?: boolean;
  defaultOpen?: boolean;
  onOpenChange?: (open: boolean) => void;
}

const itemClasses = (active?: boolean, destructive?: boolean): string =>
  cx(
    `flex justify-between items-start cursor-pointer outline-none hover:bg-stone-100 data-[highlighted]:bg-stone-100 px-2 py-1.5 rounded-lg gap-3`,
    active && `bg-stone-100`,
    destructive && `hover:!bg-red-100/50`,
  );

const renderIcon = (
  icon: DropdownMenuItemIcon | undefined,
  className: string,
): React.ReactNode => {
  if (!icon) {
    return null;
  }

  if (React.isValidElement<{ className?: string }>(icon)) {
    return React.cloneElement(icon, {
      className: cx(className, icon.props.className),
    });
  }

  if (typeof icon === `function` || (typeof icon === `object` && `render` in icon)) {
    return React.createElement(icon as React.ElementType<{ className?: string }>, {
      className,
    });
  }

  return <span className={className}>{icon}</span>;
};

const DropdownMenuItem: React.FC<Props> = ({
  title,
  description,
  icon,
  selected,
  active,
  onSelect,
  children,
  destructive,
  open,
  defaultOpen,
  onOpenChange,
}) => {
  const overlayPortalContainer = useOverlayPortalContainer();
  const textContent = (
    <VStack className="min-w-0">
      <Text
        variant="bodyStrong"
        truncate
        className={cx(selected && `!text-violet-800`, destructive && `!text-red-800`)}
      >
        {title}
      </Text>
      {description && (
        <Text
          variant="captionMuted"
          className={cx(`-mt-0.25 leading-4`, destructive && `!text-red-900/70`)}
        >
          {description}
        </Text>
      )}
    </VStack>
  );
  const content = (
    <>
      <HStack align={description ? `start` : `center`} gap={2} className="min-w-0">
        {renderIcon(
          icon,
          cx(
            `w-3.5 h-3.5 shrink-0`,
            description && `mt-0.75`,
            selected ? `text-violet-800` : `text-stone-500`,
            destructive && `!text-red-700`,
          ),
        )}
        {textContent}
      </HStack>
      {selected && !children && (
        <HStack
          justify="center"
          className="w-4 h-4 rounded-full shrink-0 bg-violet-500 self-center"
        >
          <CheckIcon
            className="w-3 h-3 text-white translate-y-[0.5px]"
            strokeWidth={3.5}
          />
        </HStack>
      )}
    </>
  );

  if (children) {
    return (
      <Menu.SubmenuRoot open={open} defaultOpen={defaultOpen} onOpenChange={onOpenChange}>
        <Menu.SubmenuTrigger className={itemClasses(active, destructive)}>
          <HStack align={description ? `start` : `center`} gap={2} className="min-w-0">
            {renderIcon(
              icon,
              cx(
                `w-3.5 h-3.5 shrink-0`,
                description && `mt-0.75`,
                selected ? `text-violet-800` : `text-stone-500`,
              ),
            )}
            {textContent}
          </HStack>
          <ChevronRightIcon className="w-4 h-4 shrink-0 self-center text-stone-500" />
        </Menu.SubmenuTrigger>
        <Menu.Portal container={overlayPortalContainer ?? undefined}>
          <Menu.Positioner sideOffset={0} alignOffset={0} className="z-[60]">
            <Menu.Popup className="z-[60] bg-white shadow-md shadow-stone-300/50 p-1 rounded-xl border border-stone-200 w-60 flex flex-col gap-1 mx-0 -mt-1 outline-none">
              {children}
            </Menu.Popup>
          </Menu.Positioner>
        </Menu.Portal>
      </Menu.SubmenuRoot>
    );
  }

  return (
    <Menu.Item onClick={() => onSelect?.()} className={itemClasses(active, destructive)}>
      {content}
    </Menu.Item>
  );
};

export default DropdownMenuItem;
