import {
  ArchiveIcon,
  CopyIcon,
  EyeIcon,
  MoreHorizontalIcon,
  PauseIcon,
  PencilIcon,
  Trash2Icon,
} from 'lucide-react';
import React from 'react';
import Button from '#/components/ui/Button';
import DropdownMenu from '#/components/ui/dropdown-menu/DropdownMenu';
import DropdownMenuItem from '#/components/ui/dropdown-menu/DropdownMenuItem';

const BasicExample: React.FC = () => (
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
      <DropdownMenuItem
        title="Rename rule"
        description="Change the visible name."
        icon={PencilIcon}
      />
      <DropdownMenuItem
        title="Duplicate"
        description="Copy settings into a new rule."
        icon={CopyIcon}
      />
      <DropdownMenuItem
        title="Pause rule"
        description="Temporarily stop enforcement."
        icon={PauseIcon}
      />
      <DropdownMenuItem
        title="Archive"
        description="Hide without deleting history."
        icon={ArchiveIcon}
      />
      <DropdownMenuItem
        title="View activity"
        description="Open recent matches."
        icon={EyeIcon}
      />
      <DropdownMenuItem
        title="Delete"
        description="Remove this rule permanently."
        icon={Trash2Icon}
      />
    </DropdownMenu>
  </div>
);

export default BasicExample;
