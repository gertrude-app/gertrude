import { KeychainCard } from '@dash/components';
import { Label } from '@shared/components';
import type { StoryFn, ComponentMeta } from '@storybook/react';

export default {
  title: 'Dashboard/Keychains/KeychainCard', // eslint-disable-line
  component: KeychainCard,
} as ComponentMeta<typeof KeychainCard>;

const Template: StoryFn<typeof KeychainCard> = (args) => <KeychainCard {...args} />;

export const ListPublic = Template.bind({});
ListPublic.args = {
  mode: `list`,
  name: `HTC`,
  numKeys: 43,
  isPublic: true,
  description: `Lorem ipsum dolor sit amet consectetur, adipisicing elit. Ipsum laboriosam aperiam quasi blanditiis.`,
  onRemove: () => {},
  removeText: `Delete`,
  editUrl: `/`,
};

export const ListPrivateNoEdit = Template.bind({});
ListPrivateNoEdit.args = {
  ...ListPublic.args,
  name: `Wilhite kids`,
  isPublic: false,
  editUrl: undefined,
  removeText: `Remove`,
};

export const ListPublicNoEdit = Template.bind({});
ListPublicNoEdit.args = {
  ...ListPublic.args,
  editUrl: undefined,
  removeText: `Remove`,
};

export const ListPrivate = Template.bind({});
ListPrivate.args = {
  ...ListPublic.args,
  name: `Wilhite kids`,
  isPublic: false,
};

export const ListPrivateNoDescription = Template.bind({});
ListPrivateNoDescription.args = {
  ...ListPrivate.args,
  description: undefined,
  name: `Wilhite kids`,
  isPublic: false,
};

export const SelectPrivate = Template.bind({});
SelectPrivate.args = {
  ...ListPrivate.args,
  mode: `select`,
  selected: false,
  onSelect: () => {},
  isPublic: false,
};

export const SelectedPrivate = Template.bind({});
SelectedPrivate.args = {
  ...SelectPrivate.args,
  selected: true,
};

export const SelectPublic = Template.bind({});
SelectPublic.args = {
  ...SelectPrivate.args,
  name: `HTC`,
  isPublic: true,
};

export const SelectedPublic = Template.bind({});
SelectedPublic.args = {
  ...SelectPublic.args,
  selected: true,
};

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
