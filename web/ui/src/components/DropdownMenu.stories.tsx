import {
  ArchiveIcon,
  ClockIcon,
  CopyIcon,
  EyeIcon,
  LaptopIcon,
  MonitorSmartphoneIcon,
  MoreHorizontalIcon,
  PauseIcon,
  PencilIcon,
  SearchIcon,
  ShieldCheckIcon,
  ShieldIcon,
  SmartphoneIcon,
  Trash2Icon,
  UserIcon,
  UsersIcon,
} from 'lucide-react';
import { fn } from 'storybook/test';
import type { Meta, StoryObj } from '@storybook/tanstack-react';
import Button from './Button';
import DropdownMenu from './DropdownMenu';
import DropdownMenuItem from './DropdownMenuItem';
import { StoryCanvas, StorySection, galleryParameters } from '#/storybook/StoryLayout';

const menuAction = fn();
const children = [`Sally`, `Franny`, `Jimmy`, `Henry`, `Alice`, `Charlie`];
const presets = [`Homework focus`, `Bedtime`, `Weekend`, `Travel day`];

const meta = {
  title: 'UI/Components/DropdownMenu',
  component: DropdownMenu,
  args: {
    trigger: (
      <Button type="button" onClick={menuAction}>
        Open menu
      </Button>
    ),
    children: <DropdownMenuItem title="Menu item" onSelect={menuAction} />,
  },
  argTypes: {
    searchable: { control: `boolean` },
    disabled: { control: `boolean` },
    children: { control: false },
    defaultOpen: { control: false },
    onOpenChange: { control: false },
    open: { control: false },
    contentClassName: { control: false },
    trigger: { control: false },
  },
  parameters: { layout: `fullscreen` },
} satisfies Meta<typeof DropdownMenu>;

export default meta;

type Story = StoryObj<typeof meta>;

export const Basic: Story = {
  parameters: galleryParameters,
  render: () => (
    <StoryCanvas>
      <StorySection title="Actions">
        <DropdownMenu
          trigger={
            <Button
              type="button"
              variant="default"
              icon={MoreHorizontalIcon}
              iconPosition="right"
              onClick={menuAction}
            >
              Rule actions
            </Button>
          }
        >
          <DropdownMenuItem
            title="Rename rule"
            description="Change the visible name."
            icon={PencilIcon}
            onSelect={menuAction}
          />
          <DropdownMenuItem
            title="Duplicate"
            description="Copy settings into a new rule."
            icon={CopyIcon}
            onSelect={menuAction}
          />
          <DropdownMenuItem
            title="Pause rule"
            description="Temporarily stop enforcement."
            icon={PauseIcon}
            onSelect={menuAction}
          />
          <DropdownMenuItem
            title="Archive"
            description="Hide without deleting history."
            icon={ArchiveIcon}
            onSelect={menuAction}
          />
          <DropdownMenuItem
            title="View activity"
            description="Open recent matches."
            icon={EyeIcon}
            onSelect={menuAction}
          />
          <DropdownMenuItem
            title="Delete"
            description="Remove this rule permanently."
            icon={Trash2Icon}
            destructive
            onSelect={menuAction}
          />
        </DropdownMenu>
      </StorySection>
    </StoryCanvas>
  ),
};

export const OpenActions: Story = {
  parameters: { ...galleryParameters, screenshotsAt: [`desktop`] },
  render: () => (
    <StoryCanvas>
      <StorySection title="Open actions">
        <DropdownMenu
          open
          trigger={
            <Button
              type="button"
              variant="default"
              icon={MoreHorizontalIcon}
              iconPosition="right"
              onClick={menuAction}
            >
              Rule actions
            </Button>
          }
        >
          <DropdownMenuItem
            title="Rename rule"
            description="Change the visible name."
            icon={PencilIcon}
            onSelect={menuAction}
          />
          <DropdownMenuItem
            title="Duplicate"
            description="Copy settings into a new rule."
            icon={CopyIcon}
            onSelect={menuAction}
          />
          <DropdownMenuItem
            title="Pause rule"
            description="Temporarily stop enforcement."
            icon={PauseIcon}
            onSelect={menuAction}
          />
          <DropdownMenuItem
            title="Delete"
            description="Remove this rule permanently."
            icon={Trash2Icon}
            destructive
            onSelect={menuAction}
          />
        </DropdownMenu>
      </StorySection>
    </StoryCanvas>
  ),
};

export const OpenSearchable: Story = {
  parameters: { ...galleryParameters, screenshotsAt: [`desktop`] },
  render: () => (
    <StoryCanvas innerClassName="max-w-3xl">
      <StorySection title="Open searchable menu">
        <DropdownMenu
          open
          searchable
          trigger={
            <Button
              type="button"
              variant="primary"
              icon={SearchIcon}
              onClick={menuAction}
            >
              Apply preset
            </Button>
          }
        >
          {presets.map((preset) => (
            <DropdownMenuItem
              key={preset}
              title={preset}
              selected={preset === `Bedtime`}
              icon={ShieldCheckIcon}
              onSelect={menuAction}
            />
          ))}
        </DropdownMenu>
      </StorySection>
    </StoryCanvas>
  ),
};

export const Searchable: Story = {
  parameters: galleryParameters,
  render: () => (
    <StoryCanvas innerClassName="max-w-3xl">
      <StorySection title="Searchable menus">
        <DropdownMenu
          searchable
          trigger={
            <Button
              type="button"
              variant="default"
              icon={SearchIcon}
              onClick={menuAction}
            >
              Find child
            </Button>
          }
        >
          {children.map((child) => (
            <DropdownMenuItem
              key={child}
              title={child}
              selected={child === `Franny`}
              icon={UserIcon}
              onSelect={menuAction}
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
              onClick={menuAction}
            >
              Apply preset
            </Button>
          }
        >
          {presets.map((preset) => (
            <DropdownMenuItem
              key={preset}
              title={preset}
              selected={preset === `Bedtime`}
              icon={ShieldCheckIcon}
              onSelect={menuAction}
            />
          ))}
        </DropdownMenu>
      </StorySection>
    </StoryCanvas>
  ),
};

export const NestedMenus: Story = {
  parameters: galleryParameters,
  render: () => (
    <StoryCanvas>
      <StorySection title="Nested menus">
        <DropdownMenu
          trigger={
            <Button
              type="button"
              variant="default"
              icon={MoreHorizontalIcon}
              iconPosition="right"
              onClick={menuAction}
            >
              Apply policy
            </Button>
          }
        >
          <DropdownMenuItem title="Children" icon={UsersIcon}>
            <DropdownMenuItem
              title="Sally"
              selected
              icon={UsersIcon}
              onSelect={menuAction}
            />
            <DropdownMenuItem title="Franny" icon={UsersIcon} onSelect={menuAction} />
            <DropdownMenuItem title="Jimmy" icon={UsersIcon} onSelect={menuAction} />
          </DropdownMenuItem>
          <DropdownMenuItem title="Devices" icon={MonitorSmartphoneIcon}>
            <DropdownMenuItem
              title="MacBook Pro"
              selected
              icon={LaptopIcon}
              onSelect={menuAction}
            />
            <DropdownMenuItem
              title="Family iPad"
              icon={SmartphoneIcon}
              onSelect={menuAction}
            />
          </DropdownMenuItem>
          <DropdownMenuItem title="Schedule" icon={ClockIcon}>
            <DropdownMenuItem title="Today" icon={ClockIcon} onSelect={menuAction} />
            <DropdownMenuItem
              title="This week"
              selected
              icon={ClockIcon}
              onSelect={menuAction}
            />
            <DropdownMenuItem title="Always" icon={ClockIcon} onSelect={menuAction} />
          </DropdownMenuItem>
          <DropdownMenuItem
            title="Protection level"
            selected
            icon={ShieldIcon}
            onSelect={menuAction}
          />
        </DropdownMenu>
      </StorySection>
    </StoryCanvas>
  ),
};

export const OpenNestedMenu: Story = {
  name: 'Open nested menu',
  parameters: { ...galleryParameters, screenshotsAt: [`desktop`] },
  render: () => (
    <StoryCanvas>
      <StorySection title="Open nested menu">
        <DropdownMenu
          open
          trigger={
            <Button
              type="button"
              variant="default"
              icon={MoreHorizontalIcon}
              iconPosition="right"
              onClick={menuAction}
            >
              Apply policy
            </Button>
          }
        >
          <DropdownMenuItem title="Children" icon={UsersIcon} open>
            <DropdownMenuItem
              title="Sally"
              selected
              icon={UsersIcon}
              onSelect={menuAction}
            />
            <DropdownMenuItem title="Franny" icon={UsersIcon} onSelect={menuAction} />
            <DropdownMenuItem title="Jimmy" icon={UsersIcon} onSelect={menuAction} />
          </DropdownMenuItem>
          <DropdownMenuItem title="Devices" icon={MonitorSmartphoneIcon}>
            <DropdownMenuItem
              title="MacBook Pro"
              selected
              icon={LaptopIcon}
              onSelect={menuAction}
            />
            <DropdownMenuItem
              title="Family iPad"
              icon={SmartphoneIcon}
              onSelect={menuAction}
            />
          </DropdownMenuItem>
          <DropdownMenuItem
            title="Protection level"
            selected
            icon={ShieldIcon}
            onSelect={menuAction}
          />
        </DropdownMenu>
      </StorySection>
    </StoryCanvas>
  ),
};
