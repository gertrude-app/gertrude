import { ComponentStory, ComponentMeta } from '@storybook/react';
import KeyCreator from './KeyCreator';
import * as EditKey from '../../../lib/keys/edit';

export default {
  title: `Dashboard/Keychains/Keys/KeyCreator`,
  component: KeyCreator,
} as ComponentMeta<typeof KeyCreator>;

const Template: ComponentStory<typeof KeyCreator> = (args) => <KeyCreator {...args} />;

export const CreateStart = Template.bind({});
CreateStart.args = {
  id: `1`,
  isNew: true,
  activeStep: EditKey.Step.SetKeyType,
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
  activeStep: EditKey.Step.WebsiteKey_SetAddress,
  address: `goats.com`,
};

export const CreateStrictAddressType = Template.bind({});
CreateStrictAddressType.args = {
  ...CreateStart.args,
  addressType: `strict`,
  keyType: `website`,
  activeStep: EditKey.Step.WebsiteKey_SetAddress,
  address: `goats.com`,
};

export const CreateAddressScope = Template.bind({});
CreateAddressScope.args = {
  ...CreateStart.args,
  addressType: `standard`,
  keyType: `website`,
  activeStep: EditKey.Step.WebsiteKey_SetAppScope,
  address: `goats.com`,
};

export const CreateExpirationOff = Template.bind({});
CreateExpirationOff.args = {
  ...CreateStart.args,
  addressType: `standard`,
  keyType: `website`,
  activeStep: EditKey.Step.Expiration,
  address: `goats.com`,
};

const expiration = new Date();
expiration.setDate(expiration.getDate() + 3);

export const CreateExpiration = Template.bind({});
CreateExpiration.args = {
  ...CreateStart.args,
  addressType: `standard`,
  keyType: `website`,
  activeStep: EditKey.Step.Expiration,
  expiration: expiration.toISOString(),
  address: `goats.com`,
};

export const EditComment = Template.bind({});
EditComment.args = {
  ...CreateExpiration.args,
  keyType: `website`,
  address: `goats.com`,
  activeStep: undefined,
  expiration: undefined,
  comment: `For AOPS`,
  isNew: false,
};

export const EditNoExpiration = Template.bind({});
EditNoExpiration.args = {
  ...CreateExpiration.args,
  keyType: `website`,
  address: `goats.com`,
  activeStep: undefined,
  isNew: false,
};

export const EditHasExpiration = Template.bind({});
EditHasExpiration.args = {
  ...CreateExpiration.args,
  keyType: `website`,
  address: `goats.com`,
  activeStep: undefined,
  expiration: expiration.toISOString(),
  isNew: false,
};

export const EditStepOpen = Template.bind({});
EditStepOpen.args = {
  ...CreateExpiration.args,
  keyType: `website`,
  address: `goats.com`,
  activeStep: EditKey.Step.WebsiteKey_SetAddress,
  isNew: false,
};

export const CreateApp = Template.bind({});
CreateApp.args = {
  ...CreateStart.args,
  keyType: `app`,
  activeStep: EditKey.Step.SetKeyType,
  address: `goats.com`,
  appIdentificationType: `slug`,
  appSlug: `slack`,
};

export const CreateAppSlug = Template.bind({});
CreateAppSlug.args = {
  ...CreateApp.args,
  activeStep: EditKey.Step.AppKey_ChooseApp,
};

export const CreateAppBundleId = Template.bind({});
CreateAppBundleId.args = {
  ...CreateApp.args,
  activeStep: EditKey.Step.AppKey_ChooseApp,
  appIdentificationType: `bundleId`,
  appBundleId: `com.goats.app`,
};

export const CreateAppScope = Template.bind({});
CreateAppScope.args = {
  ...CreateAppSlug.args,
  activeStep: EditKey.Step.AppKey_SetAppScope,
};

export const CreateAppExpiration = Template.bind({});
CreateAppExpiration.args = {
  ...CreateAppSlug.args,
  activeStep: EditKey.Step.Expiration,
};

export const CreateAppComment = Template.bind({});
CreateAppComment.args = {
  ...CreateAppSlug.args,
  activeStep: EditKey.Step.Comment,
};

export const AppKeyAddressScope = Template.bind({});
AppKeyAddressScope.args = {
  ...CreateApp.args,
  keyType: `app`,
  appScope: `address`,
  activeStep: EditKey.Step.AppKey_Advanced_SetAddress,
};

export const EditAppKeyAddressScope = Template.bind({});
EditAppKeyAddressScope.args = {
  ...CreateApp.args,
  isNew: false,
  keyType: `app`,
  appScope: `address`,
  activeStep: undefined,
};

export const WebKeyAppScope = Template.bind({});
WebKeyAppScope.args = {
  ...CreateApp.args,
  keyType: `website`,
  appScope: `address`,
  addressScope: `singleApp`,
  activeStep: EditKey.Step.WebsiteKey_Advanced_ChooseApp,
};

export const EditWebKeyAppScope = Template.bind({});
EditWebKeyAppScope.args = {
  ...WebKeyAppScope.args,
  isNew: false,
  activeStep: undefined,
};
