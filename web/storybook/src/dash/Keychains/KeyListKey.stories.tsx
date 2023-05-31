import { KeyListKey } from '@dash/components';
import type { StoryObj, Meta } from '@storybook/react';
import { keyExamples, props } from '../../story-helpers';

const meta = {
  title: 'Dashboard/Keychains/KeyListKey', // eslint-disable-line
  component: KeyListKey,
} satisfies Meta<typeof KeyListKey>;

type Story = StoryObj<typeof meta>;

export const StandardWebsite: Story = props({
  record: keyExamples.standardWeb,
  type: `list`,
});

export const StrictWebsite: Story = props({
  record: keyExamples.strictWeb,
  type: `list`,
});

export const NormalApp: Story = props({
  record: keyExamples.skeletonApp,
  type: `list`,
});

export const NormalAppWithBundleId: Story = props({
  record: keyExamples.skeletonAppBundleId,
  type: `list`,
});

export const SingleAppKey: Story = props({
  record: keyExamples.singleApp,
  type: `list`,
});

export const UnrestrictedForAllApps: Story = props({
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
  record: keyExamples.standardWeb,
  type: `table`,
});

export const StrictWebsiteTable: Story = props({
  record: keyExamples.strictWeb,
  type: `table`,
});

export const NormalAppTable: Story = props({
  record: keyExamples.skeletonApp,
  type: `table`,
});

export const NormalAppWithBundleIdTable: Story = props({
  record: keyExamples.skeletonAppBundleId,
  type: `table`,
});

export const SingleAppKeyTable: Story = props({
  record: keyExamples.singleApp,
  type: `table`,
});

export const UnrestrictedForAllAppsTable: Story = props({
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
