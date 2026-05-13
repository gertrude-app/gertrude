import Button from '#/components/ui/Button';
import DropdownMenu from '#/components/ui/dropdown-menu/DropdownMenu';
import DropdownMenuItem from '#/components/ui/dropdown-menu/DropdownMenuItem';
import { MoreHorizontalIcon } from 'lucide-react';
import React from 'react';

const BasicExample: React.FC = () => {
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
            Rule actions
          </Button>
        }
      >
        <DropdownMenuItem title="Rename rule" />
        <DropdownMenuItem title="Duplicate" />
        <DropdownMenuItem title="Pause rule" />
        <DropdownMenuItem title="Archive" />
        <DropdownMenuItem title="View activity" />
        <DropdownMenuItem title="Delete" />
      </DropdownMenu>
    </div>
  );
};

export default BasicExample;
