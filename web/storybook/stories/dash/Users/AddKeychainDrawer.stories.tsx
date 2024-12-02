import AddKeychainDrawer from '@dash/components/src/Users/AddKeychainDrawer';
import type { StoryObj, Meta } from '@storybook/react';
import { withStatefulChrome } from '../../decorators/StatefulChrome';
import { props, keychainProps } from '../../story-helpers';

const meta = {
  title: 'Dashboard/Users/AddKeychainDrawer', // eslint-disable-line
  component: AddKeychainDrawer,
  decorators: [withStatefulChrome],
  parameters: { layout: `fullscreen` },
} satisfies Meta<typeof AddKeychainDrawer>;

type Story = StoryObj<typeof meta>;

// @screenshot: xs,md
export const Loading: Story = props({
  request: { state: `ongoing` },
  selected: undefined,
  onSelect: () => {},
  schedule: undefined,
  setSchedule: () => {},
  onDismiss: () => {},
  onConfirm: () => {},
  existingKeychains: [],
  userName: `Little Jimmy`,
});

export const Failed: Story = props({
  ...Loading.args,
  request: {
    state: `failed`,
  },
});

export const NoKeychains: Story = props({
  ...Loading.args,
  request: {
    state: `succeeded`,
    payload: {
      own: [],
      public: [],
    },
  },
});

export const OnePage: Story = props({
  ...Loading.args,
  request: {
    state: `succeeded`,
    payload: {
      own: [keychainProps({ name: `HTC`, numKeys: 43, isPublic: false })],
      public: [],
    },
  },
});

export const SeveralPages: Story = props({
  ...Loading.args,
  request: {
    state: `succeeded`,
    payload: {
      own: [
        keychainProps({ name: `Lorem`, numKeys: 43, isPublic: false, id: `1` }),
        keychainProps({ name: `Ipsum`, numKeys: 43, isPublic: true }),
        keychainProps({ name: `Dolor`, numKeys: 43, isPublic: false }),
        keychainProps({ name: `Sit`, numKeys: 43, isPublic: false }),
        keychainProps({ name: `Amet`, numKeys: 43, isPublic: false }),
        keychainProps({ name: `Consectetur`, numKeys: 43, isPublic: false }),
        keychainProps({ name: `Foo`, numKeys: 43, isPublic: false }),
        keychainProps({ name: `Bar`, numKeys: 43, isPublic: false }),
        keychainProps({ name: `Baz`, numKeys: 43, isPublic: false }),
      ],
      public: [],
    },
  },
});

export const Selected: Story = props({
  ...SeveralPages.args,
  selected: keychainProps({ name: `Ipsum`, numKeys: 43, isPublic: false, id: `1` }),
  schedule: {
    mode: `active`,
    days: {
      sunday: true,
      monday: true,
      tuesday: true,
      wednesday: true,
      thursday: true,
      friday: true,
      saturday: true,
    },
    window: {
      start: { hour: 8, minute: 0 },
      end: { hour: 16, minute: 0 },
    },
  },
});

export default meta;
