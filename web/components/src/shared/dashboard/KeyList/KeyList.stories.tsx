import { ComponentStory, ComponentMeta } from '@storybook/react';
import KeyList from './KeyList';

export default {
  title: `Dashboard/Keychains/Keys/KeyList`,
  component: KeyList,
} as ComponentMeta<typeof KeyList>;

const Template: ComponentStory<typeof KeyList> = (args) => <KeyList {...args} />;

export const Default = Template.bind({});
Default.args = {
  keys: [
    // this is a "website" key of the "standard" type, unlocking `*.super-safe.com` for all web browsers
    {
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
    // this is a "website" key of the "strict" type, unlocking `github.com` for Firefox Browser
    {
      id: `1`,
      keychainId: `1`,
      key: {
        type: `domain`, // this is the "standard" address type
        domain: `github.com`,
        scope: {
          type: `single`,
          single: { type: `identifiedAppSlug`, identifiedAppSlug: `firefox-browser` },
        },
      },
      comment: `some comment`, // only sometimes there...
    },
    // this is an "app" key, granting unrestricted access to the Slack app
    {
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
    // this is a variation on the above, but with a bundle ID instead of a slug
    {
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
    // this is a "website" key of the "STRICT" type, unlocking JUST safe-api.google.com, no other subdomains
    {
      id: `4`,
      keychainId: `1`,
      key: {
        type: `domain`, // this is the "strict" address type
        domain: `safe-api.google.com`,
        scope: {
          type: `webBrowsers`,
        },
      },
      comment: undefined, // as with all other key records, this is optional, most commonly undefined
    },
    // an "advanced" configuration, a website key affecting only a single app, not as important, cuz less common
    {
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
  ],
};
