import { ComponentStory, ComponentMeta } from '@storybook/react';
import Key from './Key';

export default {
  title: `Dashboard/Keychains/Keys/Key`,
  component: Key,
} as ComponentMeta<typeof Key>;

const Template: ComponentStory<typeof Key> = (args) => <Key {...args} />;

export const StandardWebsite = Template.bind({});
StandardWebsite.args = {
  record: {
    id: `1`,
    keychainId: `1`,
    key: {
      type: `anySubdomain`, // this is the "standard" address type
      domain: `super-safe.com`,
      scope: {
        type: `webBrowsers`,
      },
    },
    comment: `some comment`, // only sometimes there...
  },
};

export const StrictWebsite = Template.bind({});
StrictWebsite.args = {
  record: {
    id: `1`,
    keychainId: `1`,
    key: {
      type: `domain`, // this is the "standard" address type
      domain: `github.com`,
      scope: {
        type: `webBrowsers`,
      },
    },
    comment: `some comment`, // only sometimes there...
  },
};

export const NormalApp = Template.bind({});
NormalApp.args = {
  record: {
    id: `2`,
    keychainId: `1`,
    key: {
      type: `skeleton`, // this means app gets unrestricted access
      scope: {
        type: `identifiedAppSlug`,
        // the key only holds a "slug", but we can look up a presentable app name
        identifiedAppSlug: `slack`,
      },
    },
    comment: `some comment`, // only sometimes there...
  },
};

export const NormalAppWithBundleId = Template.bind({});
NormalAppWithBundleId.args = {
  record: {
    id: `3`,
    keychainId: `1`,
    key: {
      type: `skeleton`, // this means app gets unrestricted access
      scope: {
        type: `bundleId`,
        // these bundle ideas are more rare, but not unheard of, and they can be LONG
        bundleId: `WE234WODK.com.lol.reallylongsomtetimes.foobar`,
      },
    },
    comment: `some comment`, // only sometimes there...
  },
};

export const SingleAppKey = Template.bind({});
SingleAppKey.args = {
  record: {
    id: `6`,
    keychainId: `1`,
    key: {
      type: `domain`,
      domain: `rad-vim-themes.biz`,
      scope: {
        type: `single`,
        single: {
          type: `identifiedAppSlug`,
          identifiedAppSlug: `vscode`,
        },
      },
    },
    comment: undefined,
  },
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
