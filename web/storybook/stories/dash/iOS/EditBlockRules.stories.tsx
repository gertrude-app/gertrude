import EditBlockRules from '@dash/components/src/iOS/EditBlockRules';
import type { Meta, StoryObj } from '@storybook/react';

const meta = {
  title: 'Dashboard/iOS/EditBlockRules', // eslint-disable-line
  component: EditBlockRules,
  parameters: { layout: `centered` },
} satisfies Meta<typeof EditBlockRules>;

type Story = StoryObj<typeof meta>;

export const Default: Story = {
  args: {
    rules: [
      {
        id: `rule1`,
        props: {
          type: `app`,
          primaryValue: `com.apple.Safari`,
          secondaryValue: ``,
          condition: `always`,
        },
      },
      {
        id: `rule2`,
        props: {
          type: `address`,
          primaryValue: `bad-site.com`,
          secondaryValue: ``,
          condition: `always`,
        },
      },
      {
        id: `rule3`,
        props: {
          type: `app`,
          primaryValue: `com.example.Game`,
          secondaryValue: `ads.com`,
          condition: `whenAddressContains`,
        },
      },
      {
        id: `rule4`,
        props: {
          type: `address`,
          primaryValue: `social.com`,
          secondaryValue: ``,
          condition: `whenIsBrowser`,
        },
        readOnly: true,
      },
      {
        id: `rule5`,
        props: {
          type: `app`,
          primaryValue: `com.netflix.Netflix`,
          secondaryValue: `foo.com\nbar.com`,
          condition: `unlessAddressContains`,
        },
        readOnly: true,
      },
    ],
    onDelete: () => {},
    onEdit: () => {},
    onAdd: () => {},
  },
};

export const Empty: Story = {
  args: {
    rules: [],
    onDelete: () => {},
    onEdit: () => {},
    onAdd: () => {},
  },
};

export default meta;
