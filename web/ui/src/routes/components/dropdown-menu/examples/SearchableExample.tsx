import Button from '#/components/ui/Button';
import DropdownMenu from '#/components/ui/dropdown-menu/DropdownMenu';
import DropdownMenuItem from '#/components/ui/dropdown-menu/DropdownMenuItem';
import { SearchIcon, ShieldCheckIcon, UserIcon } from 'lucide-react';
import React from 'react';

const children = ['Sally', 'Franny', 'Jimmy', 'Henry', 'Alice', 'Charlie'];
const presets = ['Homework focus', 'Bedtime', 'Weekend', 'Travel day'];

const SearchableExample: React.FC = () => {
  return (
    <div className="flex h-full items-center justify-center p-8">
      <div className="grid w-full max-w-2xl gap-5 sm:grid-cols-2">
        <DropdownMenu
          searchable
          trigger={
            <Button
              type="button"
              variant="default"
              icon={SearchIcon}
              onClick={() => undefined}
            >
              Find child
            </Button>
          }
        >
          {children.map((child) => (
            <DropdownMenuItem
              key={child}
              title={child}
              selected={child === 'Franny'}
              icon={UserIcon}
            />
          ))}
        </DropdownMenu>
        <DropdownMenu
          searchable
          trigger={
            <Button
              type="button"
              variant="primary"
              icon={SearchIcon}
              onClick={() => undefined}
            >
              Apply preset
            </Button>
          }
        >
          {presets.map((preset) => (
            <DropdownMenuItem
              key={preset}
              title={preset}
              selected={preset === 'Bedtime'}
              icon={ShieldCheckIcon}
            />
          ))}
        </DropdownMenu>
      </div>
    </div>
  );
};

export default SearchableExample;
