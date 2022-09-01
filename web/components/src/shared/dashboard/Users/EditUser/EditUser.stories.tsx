import { ComponentStory, ComponentMeta } from '@storybook/react';
import { withStatefulChrome } from '../../../../decorators/StatefulChrome';
import { keychainProps } from '../../story-helpers';
import EditUser from './EditUser';

export default {
  title: `Dashboard/Users/EditUser`,
  component: EditUser,
  decorators: [withStatefulChrome],
  parameters: { layout: `fullscreen` },
} as ComponentMeta<typeof EditUser>;

const Template: ComponentStory<typeof EditUser> = (args) => <EditUser {...args} />;

export const Default = Template.bind({});
Default.args = {
  name: `Little Jimmy`,
  setName: () => {},
  keyloggingEnabled: false,
  setKeyloggingEnabled: () => {},
  screenshotsEnabled: false,
  setScreenshotsEnabled: () => {},
  screenshotsFrequency: 120,
  setScreenshotsFrequency: () => {},
  screenshotsResolution: 1000,
  setScreenshotsResolution: () => {},
  keychains: [
    keychainProps({ name: `HTC`, keys: 43, isPublic: true }),
    keychainProps({ name: `Public Speaking`, keys: 7, isPublic: false }),
  ],
  devices: [
    { id: `1`, model: `M1 MacbookAir (2021)`, status: `online`, icon: `laptop` },
    { id: `2`, model: `Mac Mini (2018)`, status: `offline`, icon: `desktop` },
  ],
};
