import { Menu } from '@base-ui/react/menu';
import cx from 'clsx';
import { CheckIcon } from 'lucide-react';
import React from 'react';
import HStack from '../primitives/HStack';
import Text from '../primitives/Text';
import VStack from '../primitives/VStack';

interface Props {
  title: string;
  description?: React.ReactNode;
  checked: boolean;
  onCheckedChange: (checked: boolean) => void;
  disabled?: boolean;
  active?: boolean;
}

const DropdownMenuCheckboxItem: React.FC<Props> = ({
  title,
  description,
  checked,
  onCheckedChange,
  disabled,
  active,
}) => (
  <Menu.CheckboxItem
    checked={checked}
    onCheckedChange={onCheckedChange}
    closeOnClick={false}
    disabled={disabled}
    className={cx(
      `flex items-start gap-2.5 rounded-lg px-2 py-1.5 outline-none`,
      disabled
        ? `cursor-not-allowed opacity-50`
        : `cursor-pointer hover:bg-stone-100 data-[highlighted]:bg-stone-100`,
      active && !disabled && `bg-stone-100`,
    )}
  >
    <HStack
      as="span"
      justify="center"
      className={cx(
        `mt-0.5 h-4.5 w-4.5 shrink-0 rounded-[5px] border shadow-sm`,
        checked
          ? `border-violet-800 bg-violet-500 text-white shadow-violet-500/20`
          : `border-stone-300/80 bg-white text-transparent shadow-stone-300/30`,
      )}
    >
      <Menu.CheckboxItemIndicator keepMounted>
        <CheckIcon className="h-3.5 w-3.5" strokeWidth={3.5} />
      </Menu.CheckboxItemIndicator>
    </HStack>
    <VStack as="span" className="min-w-0 translate-y-px">
      <Text variant="bodyStrong" truncate>
        {title}
      </Text>
      {description && (
        <Text variant="captionMuted" className="leading-5">
          {description}
        </Text>
      )}
    </VStack>
  </Menu.CheckboxItem>
);

export default DropdownMenuCheckboxItem;
