import Button from '#/components/ui/Button';
import DropdownMenu from '#/components/ui/dropdown-menu/DropdownMenu';
import DropdownMenuItem from '#/components/ui/dropdown-menu/DropdownMenuItem';
import {
  ClockIcon,
  LaptopIcon,
  MonitorSmartphoneIcon,
  MoreHorizontalIcon,
  ShieldIcon,
  SmartphoneIcon,
  UsersIcon,
} from 'lucide-react';
import React from 'react';

const NestedMenuExample: React.FC = () => {
  return (
    <div className="flex h-full items-center justify-center p-8">
      <DropdownMenu
        trigger={
          <Button
            type="button"
            variant="default"
            icon={MoreHorizontalIcon}
            iconPosition="right"
            onClick={() => undefined}
          >
            Apply policy
          </Button>
        }
      >
        <DropdownMenuItem title="Children" icon={UsersIcon}>
          <DropdownMenuItem title="Sally" selected icon={UsersIcon} />
          <DropdownMenuItem title="Franny" icon={UsersIcon} />
          <DropdownMenuItem title="Jimmy" icon={UsersIcon} />
        </DropdownMenuItem>
        <DropdownMenuItem title="Devices" icon={MonitorSmartphoneIcon}>
          <DropdownMenuItem title="MacBook Pro" selected icon={LaptopIcon} />
          <DropdownMenuItem title="Family iPad" icon={SmartphoneIcon} />
        </DropdownMenuItem>
        <DropdownMenuItem title="Schedule" icon={ClockIcon}>
          <DropdownMenuItem title="Today" icon={ClockIcon} />
          <DropdownMenuItem title="This week" selected icon={ClockIcon} />
          <DropdownMenuItem title="Always" icon={ClockIcon} />
        </DropdownMenuItem>
        <DropdownMenuItem title="Protection level" selected icon={ShieldIcon} />
      </DropdownMenu>
    </div>
  );
};

export default NestedMenuExample;
