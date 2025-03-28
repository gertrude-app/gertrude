import { KeychainCard } from '@dash/components';
import { Label } from '@shared/components';
import type { StoryObj, Meta } from '@storybook/react';
import { props } from '../../story-helpers';

const meta = {
  title: 'Dashboard/Keychains/KeychainCard', // eslint-disable-line
  component: KeychainCard,
} satisfies Meta<typeof KeychainCard>;

type Story = StoryObj<typeof meta>;

export const ListPublic: Story = props({
  id: `1`,
  mode: `keychains_screen`,
  name: `HTC`,
  numKeys: 43,
  isPublic: true,
  description: `Lorem ipsum dolor sit amet consectetur, adipisicing elit. Ipsum laboriosam aperiam quasi blanditiis.`,
  onRemove: () => {},
  removeText: `Delete`,
  editUrl: `/`,
  schedulable: false,
});

const NotDuringSchoolHours: Story = props({
  numKeys: 12,
  isPublic: true,
  onRemove: () => {},
  editUrl: undefined,
  mode: `assigned_to_child`,
  keychainId: `123`,
  removeText: `Remove`,
  name: `After-school games`,
  description: `For afternoons and weekends, not to be played during school hours`,
  setSchedule: () => {},
  schedule: {
    mode: `inactive`,
    days: {
      sunday: false,
      monday: true,
      tuesday: true,
      wednesday: true,
      thursday: true,
      friday: true,
      saturday: false,
    },
    window: {
      start: { hour: 6, minute: 0 },
      end: { hour: 17, minute: 30 },
    },
  },
});

const OnlyDuringSchoolHours: Story = props({
  ...NotDuringSchoolHours.args,
  name: `History class`,
  description: `Videos for history class, only needed during school hours`,
  schedule: {
    mode: `active`,
    days: {
      sunday: false,
      monday: true,
      tuesday: true,
      wednesday: true,
      thursday: true,
      friday: true,
      saturday: false,
    },
    window: {
      start: { hour: 6, minute: 0 },
      end: { hour: 17, minute: 30 },
    },
  },
});

const NotAtNight: Story = props({
  ...NotDuringSchoolHours.args,
  name: `Only daytime`,
  description: `For daytime use only, not to be used at night`,
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
      start: {
        hour: 6,
        minute: 0,
      },
      end: {
        hour: 17,
        minute: 30,
      },
    },
  },
});

const OnlyOnWeekends: Story = props({
  ...NotDuringSchoolHours.args,
  name: `Weekend fun`,
  description: `For weekends only, not to be used during the week`,
  schedule: {
    mode: `active`,
    days: {
      sunday: true,
      monday: false,
      tuesday: false,
      wednesday: false,
      thursday: false,
      friday: false,
      saturday: true,
    },
    window: {
      start: {
        hour: 0,
        minute: 0,
      },
      end: {
        hour: 23,
        minute: 59,
      },
    },
  },
});

const Random: Story = props({
  ...NotDuringSchoolHours.args,
  name: `Seemingly random`,
  description: `Weird schedule, not sure who would use this`,
  schedule: {
    mode: `inactive`,
    days: {
      sunday: false,
      monday: true,
      tuesday: true,
      wednesday: false,
      thursday: true,
      friday: false,
      saturday: false,
    },
    window: {
      start: { hour: 3, minute: 45 },
      end: { hour: 4, minute: 4 },
    },
  },
});

const Always: Story = props({
  ...NotDuringSchoolHours.args,
  name: `Always active`,
  description: `Not sure why you'd have this one scheduled...`,
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
      start: { hour: 0, minute: 0 },
      end: { hour: 23, minute: 59 },
    },
  },
});

export const Scheduled = () => (
  <div className="flex flex-col gap-8">
    <KeychainCard {...(NotDuringSchoolHours.args as any)} />
    <KeychainCard {...(OnlyDuringSchoolHours.args as any)} />
    <KeychainCard {...(NotAtNight.args as any)} />
    <KeychainCard {...(OnlyOnWeekends.args as any)} />
    <KeychainCard {...(Random.args as any)} />
    <KeychainCard {...(Always.args as any)} />
  </div>
);

export const ListPrivateNoEdit: Story = props({
  ...ListPublic.args,
  name: `Wilhite kids`,
  isPublic: false,
  editUrl: undefined,
  removeText: `Remove`,
  schedulable: true,
});

export const ListPublicNoEdit: Story = props({
  ...ListPublic.args,
  editUrl: undefined,
  removeText: `Remove`,
  schedulable: true,
});

export const ListPrivate: Story = props({
  ...ListPublic.args,
  name: `Wilhite kids`,
  isPublic: false,
});

export const ListPrivateNoDescription: Story = props({
  ...ListPrivate.args,
  description: undefined,
  name: `Wilhite kids`,
  isPublic: false,
});

export const Schedulable: Story = props({
  ...ListPrivateNoDescription.args,
  isPublic: true,
  mode: `assign_to_child`,
  setSchedule: () => {},
  onRemove: () => {},
});

export const SelectPrivate: Story = props({
  ...ListPrivate.args,
  mode: `select`,
  selected: false,
  onSelect: () => {},
  isPublic: false,
});

export const SelectedPrivate: Story = props({
  ...SelectPrivate.args,
  selected: true,
});

export const SelectPublic: Story = props({
  ...SelectPrivate.args,
  name: `HTC`,
  isPublic: true,
});

export const SelectedPublic: Story = props({
  ...SelectPublic.args,
  selected: true,
});

// @screenshot: xs/1200,sm/1200,md/1200
export const Collection = () => (
  <div className="flex flex-col gap-4 max-w-[875px]">
    <Label>
      Mode: <code>list</code>
    </Label>
    <div className="flex flex-col gap-4">
      <KeychainCard {...(ListPublic.args as any)} />
      <KeychainCard {...(ListPublicNoEdit.args as any)} />
      <KeychainCard {...(ListPrivate.args as any)} />
      <KeychainCard {...(ListPrivateNoEdit.args as any)} />
      <KeychainCard {...(ListPrivateNoDescription.args as any)} />
      <KeychainCard {...(Schedulable.args as any)} />
      <KeychainCard {...(NotDuringSchoolHours.args as any)} />
      <KeychainCard {...(OnlyDuringSchoolHours.args as any)} />
      <KeychainCard {...(NotAtNight.args as any)} />
      <KeychainCard {...(OnlyOnWeekends.args as any)} />
      <KeychainCard {...(Random.args as any)} />
      <KeychainCard {...(Always.args as any)} />
    </div>
    <Label className="mt-3">
      Mode: <code>select</code>
    </Label>
    <div className="max-w-[510px] flex flex-col gap-4">
      <KeychainCard {...(SelectPrivate.args as any)} />
      <KeychainCard {...(SelectedPrivate.args as any)} />
      <KeychainCard {...(SelectPublic.args as any)} />
      <KeychainCard {...(SelectedPublic.args as any)} />
    </div>
  </div>
);

export default meta;
