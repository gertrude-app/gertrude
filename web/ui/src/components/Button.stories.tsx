import {
  ArrowRightIcon,
  CheckIcon,
  HeartIcon,
  PlusIcon,
  SettingsIcon,
  TrashIcon,
} from 'lucide-react';
import { fn } from 'storybook/test';
import type { Meta, StoryObj } from '@storybook/tanstack-react';
import Button from './Button';
import { StoryCanvas, StorySection, galleryParameters } from '#/storybook/StoryLayout';

const buttonAction = fn();

const variants = [`primary`, `default`, `ghost`, `destructive`, `selected`] as const;
const sizes = [`small`, `medium`, `large`] as const;
const meta = {
  title: 'UI/Components/Button',
  component: Button,
  args: { type: `button`, onClick: buttonAction },
  argTypes: {
    children: { control: `text` },
    variant: { options: variants, control: { type: `inline-radio` } },
    size: { options: sizes, control: { type: `inline-radio` } },
    loading: { control: `boolean` },
    disabled: { control: `boolean` },
    onClick: { control: false },
  },
  parameters: { layout: `fullscreen` },
} satisfies Meta<typeof Button>;

export default meta;

type Story = StoryObj<typeof meta>;

export const Assortment: Story = {
  parameters: galleryParameters,
  render: () => (
    <StoryCanvas>
      <StorySection title="Common actions">
        <Button type="button" onClick={buttonAction} variant="primary" icon={PlusIcon}>
          Add person
        </Button>
        <Button type="button" onClick={buttonAction} icon={SettingsIcon}>
          Settings
        </Button>
        <Button type="button" onClick={buttonAction} variant="ghost">
          Cancel
        </Button>
        <Button
          type="button"
          onClick={buttonAction}
          variant="destructive"
          icon={TrashIcon}
        >
          Delete
        </Button>
      </StorySection>
      <StorySection title="Button types">
        <Button type="submit" variant="primary" icon={CheckIcon}>
          Submit form
        </Button>
        <Button type="link" href="/people" icon={ArrowRightIcon} iconPosition="right">
          Internal link
        </Button>
        <Button
          type="link"
          href="https://gertrude.app"
          icon={ArrowRightIcon}
          iconPosition="right"
        >
          External link
        </Button>
      </StorySection>
      <StorySection title="Icon treatments">
        <Button type="button" onClick={buttonAction} icon={HeartIcon} fillIcon>
          Filled icon
        </Button>
        <Button
          type="button"
          onClick={buttonAction}
          icon={ArrowRightIcon}
          iconPosition="right"
        >
          Right icon
        </Button>
        <Button
          type="button"
          onClick={buttonAction}
          icon={SettingsIcon}
          ariaLabel="Settings"
        />
      </StorySection>
    </StoryCanvas>
  ),
};

export const Variants: Story = {
  parameters: galleryParameters,
  render: () => (
    <StoryCanvas>
      {variants.map((variant) => (
        <StorySection key={variant} title={variant}>
          <Button type="button" onClick={buttonAction} variant={variant}>
            Text
          </Button>
          <Button type="button" onClick={buttonAction} variant={variant} icon={PlusIcon}>
            With icon
          </Button>
          <Button type="button" onClick={buttonAction} variant={variant} loading>
            Loading
          </Button>
          <Button type="button" onClick={buttonAction} variant={variant} disabled>
            Disabled
          </Button>
        </StorySection>
      ))}
    </StoryCanvas>
  ),
};

export const Sizes: Story = {
  parameters: galleryParameters,
  render: () => (
    <StoryCanvas>
      {sizes.map((size) => (
        <StorySection key={size} title={size}>
          <Button type="button" onClick={buttonAction} size={size}>
            {size}
          </Button>
          <Button type="button" onClick={buttonAction} size={size} icon={PlusIcon}>
            With icon
          </Button>
          <Button
            type="button"
            onClick={buttonAction}
            size={size}
            icon={SettingsIcon}
            ariaLabel={`${size} settings`}
          />
          <Button type="button" onClick={buttonAction} size={size} loading>
            Loading
          </Button>
        </StorySection>
      ))}
    </StoryCanvas>
  ),
};

export const SplitActions: Story = {
  parameters: galleryParameters,
  render: () => (
    <StoryCanvas>
      <StorySection title="Basic split actions">
        <Button
          type="button"
          onClick={buttonAction}
          variant="primary"
          icon={CheckIcon}
          dropdownAriaLabel="More save actions"
          dropdownItems={[
            {
              title: `Save draft`,
              icon: CheckIcon,
              selected: true,
              onSelect: buttonAction,
            },
            { title: `Save and close`, icon: ArrowRightIcon, onSelect: buttonAction },
            { title: `Delete instead`, icon: TrashIcon, onSelect: buttonAction },
          ]}
        >
          Save
        </Button>
        <Button
          type="button"
          onClick={buttonAction}
          icon={TrashIcon}
          variant="destructive"
          disabled
          dropdownItems={[
            { title: `Delete selected`, icon: TrashIcon, onSelect: buttonAction },
            { title: `Archive instead`, icon: CheckIcon, onSelect: buttonAction },
          ]}
        >
          Delete
        </Button>
      </StorySection>
      <StorySection title="Searchable dropdowns">
        <Button
          type="button"
          onClick={buttonAction}
          icon={SettingsIcon}
          dropdownSearchable
          dropdownItems={[
            { title: `General`, description: `Default settings`, icon: SettingsIcon },
            {
              title: `Favorites`,
              description: `Frequently used settings`,
              icon: HeartIcon,
              selected: true,
            },
            { title: `Archive`, description: `Less common settings`, icon: CheckIcon },
          ]}
        >
          Configure
        </Button>
      </StorySection>
    </StoryCanvas>
  ),
};
