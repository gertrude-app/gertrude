import { KeyCreator } from '@dash/components';
import { EditKey } from '@dash/keys';
import type { StoryObj, Meta } from '@storybook/react';
import { props, time } from '../../story-helpers';

const meta = {
  title: 'Dashboard/KeyCreator/KeyCreator', // eslint-disable-line
  component: KeyCreator,
} satisfies Meta<typeof KeyCreator>;

type Story = StoryObj<typeof meta>;

// @screenshot xs/600,md/550
export const CreateStart: Story = props({
  id: `1`,
  isNew: true,
  activeStep: EditKey.Step.SetKeyType,
  keychainId: `kc1`,
  address: ``,
  addressType: `standard`,
  addressScope: `webBrowsers`,
  appIdentificationType: `slug`,
  showAdvancedAddressOptions: false,
  showAdvancedAddressScopeOptions: false,
  appScope: `unrestricted`,
  update: () => {},
  apps: [
    { slug: `slack`, name: `Slack` },
    { slug: `chrome`, name: `Chrome` },
    { slug: `figma`, name: `Figma` },
    { slug: `notes`, name: `Notes` },
    { slug: `firefox`, name: `Firefox` },
    { slug: `slug`, name: `Skype` },
    { slug: `vscode`, name: `Vscode` },
  ],
});

// @screenshot xs/600,md/550
export const CreateAddressType: Story = props({
  ...CreateStart.args,
  keyType: `website`,
  activeStep: EditKey.Step.WebsiteKey_SetAddress,
  address: `goats.com`,
});

export const CreateStrictAddressType: Story = props({
  ...CreateStart.args,
  addressType: `strict`,
  keyType: `website`,
  activeStep: EditKey.Step.WebsiteKey_SetAddress,
  address: `goats.com`,
});

// @screenshot xs/600,md/550
export const CreateAddressScope: Story = props({
  ...CreateStart.args,
  addressType: `standard`,
  keyType: `website`,
  activeStep: EditKey.Step.WebsiteKey_SetAppScope,
  address: `goats.com`,
});

export const CreateExpirationOff: Story = props({
  ...CreateStart.args,
  addressType: `standard`,
  keyType: `website`,
  activeStep: EditKey.Step.Expiration,
  address: `goats.com`,
});

// @screenshot xs/600,md/550
export const CreateExpiration: Story = props({
  ...CreateStart.args,
  addressType: `standard`,
  keyType: `website`,
  activeStep: EditKey.Step.Expiration,
  expiration: time.stable(),
  address: `goats.com`,
});

// @screenshot xs/600,md/550
export const EditComment: Story = props({
  ...CreateExpiration.args,
  keyType: `website`,
  address: `goats.com`,
  activeStep: EditKey.Step.None,
  expiration: undefined,
  comment: `For AOPS`,
  isNew: false,
});

export const EditNoComment: Story = props({
  ...CreateExpiration.args,
  keyType: `website`,
  address: `goats.com`,
  activeStep: EditKey.Step.None,
  isNew: false,
});

export const EditHasExpiration: Story = props({
  ...CreateExpiration.args,
  keyType: `website`,
  address: `goats.com`,
  activeStep: EditKey.Step.None,
  expiration: time.stable(),
  isNew: false,
});

// @screenshot xs/600,md/550
export const EditStepOpen: Story = props({
  ...CreateExpiration.args,
  keyType: `website`,
  address: `goats.com`,
  activeStep: EditKey.Step.WebsiteKey_SetAddress,
  isNew: false,
});

export const CreateApp: Story = props({
  ...CreateStart.args,
  keyType: `app`,
  activeStep: EditKey.Step.SetKeyType,
  address: `goats.com`,
  appIdentificationType: `slug`,
  appSlug: `slack`,
});

// @screenshot xs/600,md/550
export const CreateAppSlug: Story = props({
  ...CreateApp.args,
  activeStep: EditKey.Step.AppKey_ChooseApp,
});

export const CreateAppBundleId: Story = props({
  ...CreateApp.args,
  activeStep: EditKey.Step.AppKey_ChooseApp,
  appIdentificationType: `bundleId`,
  appBundleId: `com.goats.app`,
});

// @screenshot xs/600,md/550
export const CreateAppScope: Story = props({
  ...CreateAppSlug.args,
  activeStep: EditKey.Step.AppKey_SetAppScope,
});

export const CreateAppExpiration: Story = props({
  ...CreateAppSlug.args,
  activeStep: EditKey.Step.Expiration,
});

export const CreateAppComment: Story = props({
  ...CreateAppSlug.args,
  activeStep: EditKey.Step.Comment,
});

// @screenshot xs/600,md/550
export const AppKeyAddressScope: Story = props({
  ...CreateApp.args,
  keyType: `app`,
  appScope: `address`,
  activeStep: EditKey.Step.AppKey_Advanced_SetAddress,
});

export const EditAppKeyBundleId: Story = props({
  ...CreateApp.args,
  isNew: false,
  keyType: `app`,
  activeStep: EditKey.Step.None,
  appBundleId: `com.unknown.app`,
  appSlug: undefined,
  appIdentificationType: `bundleId`,
});

export const EditAppKeyAddressScope: Story = props({
  ...CreateApp.args,
  isNew: false,
  keyType: `app`,
  appScope: `address`,
  activeStep: EditKey.Step.None,
});

// @screenshot xs/600,md/550
export const WebKeyAppScope: Story = props({
  ...CreateApp.args,
  keyType: `website`,
  appScope: `address`,
  addressScope: `singleApp`,
  activeStep: EditKey.Step.WebsiteKey_Advanced_ChooseApp,
});

export const EditWebKeyAppScope: Story = props({
  ...WebKeyAppScope.args,
  isNew: false,
  activeStep: EditKey.Step.None,
});

export default meta;
