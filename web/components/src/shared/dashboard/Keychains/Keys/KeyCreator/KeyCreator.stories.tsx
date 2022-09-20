import { ComponentStory, ComponentMeta } from '@storybook/react';
import KeyCreator from './KeyCreator';

export default {
  title: `Dashboard/Keychains/Keys/KeyCreator`,
  component: KeyCreator,
} as ComponentMeta<typeof KeyCreator>;

const Template: ComponentStory<typeof KeyCreator> = (args) => <KeyCreator {...args} />;

export const CreateStart = Template.bind({});
CreateStart.args = {
  mode: `create`,
  currentStep: `setKeyType`,
  address: ``,
  addressType: `standard`,
  addressScope: `webBrowsers`,
  appIdentificationType: `slug`,
  showAdvancedAddressOptions: false,
  showAdvancedAddressScopeOptions: false,
  appScope: `unrestricted`,
  apps: [
    { slug: `slack`, name: `Slack` },
    { slug: `chrome`, name: `Chrome` },
    { slug: `figma`, name: `Figma` },
    { slug: `notes`, name: `Notes` },
    { slug: `firefox`, name: `Firefox` },
    { slug: `slug`, name: `Skype` },
    { slug: `vscode`, name: `Vscode` },
  ],
};

export const CreateAddressType = Template.bind({});
CreateAddressType.args = {
  ...CreateStart.args,
  keyType: `website`,
  currentStep: `websiteKey_setAddress`,
  address: `goats.com`,
};

export const CreateStrictAddressType = Template.bind({});
CreateStrictAddressType.args = {
  ...CreateStart.args,
  addressType: `strict`,
  keyType: `website`,
  currentStep: `websiteKey_setAddress`,
  address: `goats.com`,
};

export const CreateAddressScope = Template.bind({});
CreateAddressScope.args = {
  ...CreateStart.args,
  addressType: `standard`,
  keyType: `website`,
  currentStep: `websiteKey_setAppScope`,
  address: `goats.com`,
};

export const CreateExpiration = Template.bind({});
CreateExpiration.args = {
  ...CreateStart.args,
  addressType: `standard`,
  keyType: `website`,
  currentStep: `expiration`,
  address: `goats.com`,
};

export const EditComment = Template.bind({});
EditComment.args = {
  ...CreateExpiration.args,
  keyType: `website`,
  address: `goats.com`,
  currentStep: undefined,
  expiration: undefined,
  comment: `For AOPS`,
  mode: `edit`,
};

export const EditNoExpiration = Template.bind({});
EditNoExpiration.args = {
  ...CreateExpiration.args,
  keyType: `website`,
  address: `goats.com`,
  currentStep: undefined,
  mode: `edit`,
};

const expiration = new Date();
expiration.setDate(expiration.getDate() + 3);

export const EditHasExpiration = Template.bind({});
EditHasExpiration.args = {
  ...CreateExpiration.args,
  keyType: `website`,
  address: `goats.com`,
  currentStep: undefined,
  expiration,
  mode: `edit`,
};

export const EditStepOpen = Template.bind({});
EditStepOpen.args = {
  ...CreateExpiration.args,
  keyType: `website`,
  address: `goats.com`,
  currentStep: `websiteKey_setAddress`,
  mode: `edit`,
};

export const CreateApp = Template.bind({});
CreateApp.args = {
  ...CreateStart.args,
  keyType: `app`,
  currentStep: `setKeyType`,
  address: `goats.com`,
  appIdentificationType: `slug`,
  appSlug: `slack`,
};

export const CreateAppSlug = Template.bind({});
CreateAppSlug.args = {
  ...CreateApp.args,
  currentStep: `appKey_chooseApp`,
};

export const CreateAppBundleId = Template.bind({});
CreateAppBundleId.args = {
  ...CreateApp.args,
  currentStep: `appKey_chooseApp`,
  appIdentificationType: `bundleId`,
  appBundleId: `com.goats.app`,
};

export const CreateAppScope = Template.bind({});
CreateAppScope.args = {
  ...CreateAppSlug.args,
  currentStep: `appKey_setAppScope`,
};

export const CreateAppExpiration = Template.bind({});
CreateAppExpiration.args = {
  ...CreateAppSlug.args,
  currentStep: `expiration`,
};

export const CreateAppComment = Template.bind({});
CreateAppComment.args = {
  ...CreateAppSlug.args,
  currentStep: `comment`,
};

export const AppKeyAddressScope = Template.bind({});
AppKeyAddressScope.args = {
  ...CreateApp.args,
  keyType: `app`,
  appScope: `address`,
  currentStep: `appKey_setAddress`,
};

export const EditAppKeyAddressScope = Template.bind({});
EditAppKeyAddressScope.args = {
  ...CreateApp.args,
  mode: `edit`,
  keyType: `app`,
  appScope: `address`,
  currentStep: undefined,
};

export const WebKeyAppScope = Template.bind({});
WebKeyAppScope.args = {
  ...CreateApp.args,
  keyType: `website`,
  appScope: `address`,
  addressScope: `singleApp`,
  currentStep: `websiteKey_chooseApp`,
};

export const EditWebKeyAppScope = Template.bind({});
EditWebKeyAppScope.args = {
  ...WebKeyAppScope.args,
  mode: `edit`,
  currentStep: undefined,
};
