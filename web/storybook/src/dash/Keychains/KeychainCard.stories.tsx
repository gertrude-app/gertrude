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
  mode: `list`,
  name: `HTC`,
  numKeys: 43,
  isPublic: true,
  description: `Lorem ipsum dolor sit amet consectetur, adipisicing elit. Ipsum laboriosam aperiam quasi blanditiis.`,
  onRemove: () => {},
  removeText: `Delete`,
  editUrl: `/`,
});

export const ListPrivateNoEdit: Story = props({
  ...ListPublic.args,
  name: `Wilhite kids`,
  isPublic: false,
  editUrl: undefined,
  removeText: `Remove`,
});

export const ListPublicNoEdit: Story = props({
  ...ListPublic.args,
  editUrl: undefined,
  removeText: `Remove`,
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
