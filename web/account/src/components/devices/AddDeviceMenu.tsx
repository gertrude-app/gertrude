import { AppIcon, Button, DropdownMenu, DropdownMenuItem } from '@gertrude/ui';
import { PlusIcon } from 'lucide-react';
import React from 'react';
import type { SetupApp } from '#/components/onboarding/setupApps';
import { gertrudeApps } from '#/lib/gertrudeApps';

const apps: { app: SetupApp; platform: string }[] = [
  { app: `mac`, platform: `Mac` },
  { app: `blocker`, platform: `iPhone or iPad` },
  { app: `music`, platform: `iPhone or iPad` },
  { app: `podcasts`, platform: `iPhone or iPad` },
];

interface Props {
  onSelect: (app: SetupApp) => void;
  variant?: `primary` | `default`;
  disabled?: boolean;
}

const AddDeviceMenu: React.FC<Props> = ({ onSelect, variant = `primary`, disabled }) => (
  <DropdownMenu
    disabled={disabled}
    contentClassName="w-64"
    trigger={
      <Button
        type="button"
        variant={variant}
        icon={PlusIcon}
        disabled={disabled}
        onClick={() => {}}
      >
        Add a device
      </Button>
    }
  >
    {apps.map(({ app, platform }) => (
      <DropdownMenuItem
        key={app}
        title={gertrudeApps[app].name}
        description={platform}
        icon={
          <AppIcon
            src={gertrudeApps[app].icon}
            outlined={gertrudeApps[app].iconOutlined}
            className="!size-7 !rounded-lg"
          />
        }
        onSelect={() => onSelect(app)}
      />
    ))}
  </DropdownMenu>
);

export default AddDeviceMenu;
