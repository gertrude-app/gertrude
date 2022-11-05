import { KeyListKey } from '@dash/components';
import type { ComponentStory, ComponentMeta } from '@storybook/react';
import { keyExamples } from '../../story-helpers';

export default {
  title: `Dashboard/Keychains/KeyListKey`,
  component: KeyListKey,
} as ComponentMeta<typeof KeyListKey>;

const Template: ComponentStory<typeof KeyListKey> = (args) => <KeyListKey {...args} />;

export const StandardWebsite = Template.bind({});
StandardWebsite.args = {
  record: keyExamples.standardWeb,
};

export const StrictWebsite = Template.bind({});
StrictWebsite.args = {
  record: keyExamples.strictWeb,
};

export const NormalApp = Template.bind({});
NormalApp.args = {
  record: keyExamples.skeletonApp,
};

export const NormalAppWithBundleId = Template.bind({});
NormalAppWithBundleId.args = {
  record: keyExamples.skeletonAppBundleId,
};

export const SingleAppKey = Template.bind({});
SingleAppKey.args = {
  record: keyExamples.singleApp,
};

export const UnrestrictedForAllApps = Template.bind({});
UnrestrictedForAllApps.args = {
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
};
