import { BlockRuleEditor } from '@dash/components';
import type { Meta, StoryObj } from '@storybook/react';
import { props } from '../../story-helpers';

const meta = {
  title: 'Dashboard/iOS/BlockRuleEditor', // eslint-disable-line
  component: BlockRuleEditor,
  parameters: { layout: `fullscreen` },
} satisfies Meta<typeof BlockRuleEditor>;

type Story = StoryObj<typeof meta>;

export const AppAlways: Story = props({
  type: `app`,
  primaryValue: `com.apple.Safari`,
  secondaryValue: ``,
  condition: `always`,
  emit: () => {},
});

export const AppWhenAddressContains: Story = props({
  type: `app`,
  primaryValue: `com.apple.Safari`,
  secondaryValue: `bad-site.com`,
  condition: `whenAddressContains`,
  emit: () => {},
});

export const AppWhenIsBrowser: Story = props({
  type: `app`,
  primaryValue: `com.apple.Safari`,
  secondaryValue: ``,
  condition: `whenIsBrowser`,
  emit: () => {},
});

export const AppUnlessAddressContains: Story = props({
  type: `app`,
  primaryValue: `com.apple.Safari`,
  secondaryValue: `foo.com\nbar.com`,
  condition: `unlessAddressContains`,
  emit: () => {},
});

export const AddressAlways: Story = props({
  type: `address`,
  primaryValue: `example.com`,
  secondaryValue: ``,
  condition: `always`,
  emit: () => {},
});

export const AddressWhenIsBrowser: Story = props({
  type: `address`,
  primaryValue: `example.com`,
  secondaryValue: ``,
  condition: `whenIsBrowser`,
  emit: () => {},
});

export default meta;
