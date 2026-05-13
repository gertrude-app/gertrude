import Button from '#/components/ui/Button';
import DropdownMenu from '#/components/ui/dropdown-menu/DropdownMenu';
import DropdownMenuItem from '#/components/ui/dropdown-menu/DropdownMenuItem';
import { ChevronDownIcon, ClockIcon, ShieldCheckIcon, UsersIcon } from 'lucide-react';
import React from 'react';

const SelectedItemsExample: React.FC = () => {
  return (
    <div className="flex h-full items-center justify-center p-8">
      <div className="grid w-full max-w-3xl gap-5 sm:grid-cols-3">
        <DropdownMenu
          trigger={
            <Button
              type="button"
              variant="default"
              icon={ChevronDownIcon}
              iconPosition="right"
              onClick={() => undefined}
            >
              Sally
            </Button>
          }
        >
          <DropdownMenuItem title="Sally" selected />
          <DropdownMenuItem title="Franny" />
          <DropdownMenuItem title="Jimmy" />
        </DropdownMenu>
        <DropdownMenu
          trigger={
            <Button
              type="button"
              variant="default"
              icon={ChevronDownIcon}
              iconPosition="right"
              onClick={() => undefined}
            >
              Homework focus
            </Button>
          }
        >
          <DropdownMenuItem title="Homework focus" selected icon={ShieldCheckIcon} />
          <DropdownMenuItem title="Bedtime" icon={ClockIcon} />
          <DropdownMenuItem title="Weekend" icon={UsersIcon} />
        </DropdownMenu>
        <DropdownMenu
          trigger={
            <Button
              type="button"
              variant="default"
              icon={ChevronDownIcon}
              iconPosition="right"
              onClick={() => undefined}
            >
              Ask parent
            </Button>
          }
        >
          <DropdownMenuItem title="Ask parent" selected />
          <DropdownMenuItem title="Block until tomorrow" />
          <DropdownMenuItem title="Allow school sites" />
        </DropdownMenu>
      </div>
    </div>
  );
};

export default SelectedItemsExample;
