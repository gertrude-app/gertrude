import { ComponentStory, ComponentMeta } from '@storybook/react';
import { keyExamples } from '../story-helpers';
import Key from './Key';

export default {
  title: `Dashboard/Keychains/Keys/Key`,
  component: Key,
} as ComponentMeta<typeof Key>;

const Template: ComponentStory<typeof Key> = (args) => <Key {...args} />;

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
