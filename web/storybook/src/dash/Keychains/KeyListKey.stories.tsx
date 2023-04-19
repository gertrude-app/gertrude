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
});

export const StrictWebsite: Story = props({
  record: keyExamples.strictWeb,
});

export const NormalApp: Story = props({
  record: keyExamples.skeletonApp,
});

export const NormalAppWithBundleId: Story = props({
  record: keyExamples.skeletonAppBundleId,
});

export const SingleAppKey: Story = props({
  record: keyExamples.singleApp,
});

export const UnrestrictedForAllApps: Story = props({
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
