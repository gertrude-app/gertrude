import { KeyCreator } from '@dash/components';
import { EditKey } from '@dash/keys';
import type { Meta, StoryObj } from '@storybook/react';
import { props, time } from '../../story-helpers';

const meta = {
  title: 'Dashboard/KeyCreator/KeyCreator',
  component: KeyCreator,
} satisfies Meta<typeof KeyCreator>;

type Story = StoryObj<typeof meta>;

// @screenshot xs/600,md/550
export const CreateStart: Story = props({
  id: `1`,
  isNew: true,
  activeStep: EditKey.Step.SetAddress,
  keychainId: `kc1`,
  address: ``,
  addressType: `standard`,
  addressScope: `webBrowsers`,
  appIdentificationType: `slug`,
  showAdvancedAddressOptions: false,
  showAdvancedAddressScopeOptions: false,
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
  activeStep: EditKey.Step.SetAddress,
  address: `goats.com`,
});

export const CreateStrictAddressType: Story = props({
  ...CreateStart.args,
  addressType: `strict`,
  activeStep: EditKey.Step.SetAddress,
  address: `goats.com`,
});

// @screenshot xs/600,md/550
export const CreateAddressScope: Story = props({
  ...CreateStart.args,
  addressType: `standard`,
  activeStep: EditKey.Step.SetAppScope,
  address: `goats.com`,
});

export const CreateExpirationOff: Story = props({
  ...CreateStart.args,
  addressType: `standard`,
  activeStep: EditKey.Step.Expiration,
  address: `goats.com`,
});

// @screenshot xs/600,md/550
export const CreateExpiration: Story = props({
  ...CreateStart.args,
  addressType: `standard`,
  activeStep: EditKey.Step.Expiration,
  expiration: time.stable(),
  address: `goats.com`,
});

// @screenshot xs/600,md/550
export const EditComment: Story = props({
  ...CreateExpiration.args,
  address: `goats.com`,
  activeStep: EditKey.Step.None,
  expiration: undefined,
  comment: `For AOPS`,
  isNew: false,
});

export const EditNoComment: Story = props({
  ...CreateExpiration.args,
  address: `goats.com`,
  activeStep: EditKey.Step.None,
  isNew: false,
});

export const EditHasExpiration: Story = props({
  ...CreateExpiration.args,
  address: `goats.com`,
  activeStep: EditKey.Step.None,
  expiration: time.adding({ days: 7 }),
  isNew: false,
});

// @screenshot xs/600,md/550
export const EditStepOpen: Story = props({
  ...CreateExpiration.args,
  address: `goats.com`,
  activeStep: EditKey.Step.SetAddress,
  expiration: time.adding({ days: 7 }),
  isNew: false,
});

// @screenshot xs/600,md/550
export const WebKeyAppScope: Story = props({
  ...CreateStart.args,
  address: `goats.com`,
  appSlug: `slack`,
  addressScope: `singleApp`,
  showAdvancedAddressScopeOptions: true,
  activeStep: EditKey.Step.Advanced_ChooseApp,
});

export const EditWebKeyAppScope: Story = props({
  ...WebKeyAppScope.args,
  isNew: false,
  activeStep: EditKey.Step.None,
});

export const EditWebKeyBundleId: Story = props({
  ...WebKeyAppScope.args,
  isNew: false,
  activeStep: EditKey.Step.None,
  appBundleId: `com.unknown.app`,
  appSlug: undefined,
  appIdentificationType: `bundleId`,
});

export default meta;
