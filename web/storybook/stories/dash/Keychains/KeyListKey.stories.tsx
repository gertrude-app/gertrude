import { KeyListKey } from '@dash/components';
import type { Meta, StoryObj } from '@storybook/react';
import { keyExamples, props } from '../../story-helpers';

const meta = {
  title: 'Dashboard/Keychains/KeyListKey', // eslint-disable-line
  component: KeyListKey,
} satisfies Meta<typeof KeyListKey>;

type Story = StoryObj<typeof meta>;

export const StandardWebsite: Story = props({
  onClick: () => {},
  onDelete: () => {},
  record: keyExamples.standardWeb,
  type: `list`,
});

export const StrictWebsite: Story = props({
  ...StandardWebsite.args,
  record: keyExamples.strictWeb,
  type: `list`,
});

export const NormalApp: Story = props({
  ...StandardWebsite.args,
  record: keyExamples.skeletonApp,
  type: `list`,
});

export const NormalAppWithBundleId: Story = props({
  ...StandardWebsite.args,
  record: keyExamples.skeletonAppBundleId,
  type: `list`,
});

export const SingleAppKey: Story = props({
  ...StandardWebsite.args,
  record: keyExamples.singleApp,
  type: `list`,
});

export const UnrestrictedForAllApps: Story = props({
  ...StandardWebsite.args,
  type: `list`,
  record: {
    id: `6`,
    keychainId: `1`,
    key: {
      type: `domain`,
      domain: `rad-vim-themes.biz`,
      scope: {
        type: `unrestricted`,
      },
    },
    comment: undefined,
  },
});

export const StandardWebsiteTable: Story = props({
  ...StandardWebsite.args,
  record: keyExamples.standardWeb,
  type: `table`,
});

export const StrictWebsiteTable: Story = props({
  ...StandardWebsite.args,
  record: keyExamples.strictWeb,
  type: `table`,
});

export const NormalAppTable: Story = props({
  ...StandardWebsite.args,
  record: keyExamples.skeletonApp,
  type: `table`,
});

export const NormalAppWithBundleIdTable: Story = props({
  ...StandardWebsite.args,
  record: keyExamples.skeletonAppBundleId,
  type: `table`,
});

export const SingleAppKeyTable: Story = props({
  ...StandardWebsite.args,
  record: keyExamples.singleApp,
  type: `table`,
});

export const UnrestrictedForAllAppsTable: Story = props({
  ...StandardWebsite.args,
  type: `table`,
  record: {
    id: `6`,
    keychainId: `1`,
    key: {
      type: `domain`,
      domain: `rad-vim-themes.biz`,
      scope: {
        type: `unrestricted`,
      },
    },
    comment: undefined,
  },
});

export default meta;
