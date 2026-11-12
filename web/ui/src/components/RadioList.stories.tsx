import type { Meta, StoryObj } from '@storybook/tanstack-react';
import RadioList from './RadioList';
import { StoryCanvas, StorySection, galleryParameters } from '#/storybook/StoryLayout';

const people = [
  { value: `jude`, label: `Jude` },
  { value: `kara`, label: `Kara` },
  { value: `george`, label: `George` },
];

const noop = (): void => {};

const meta = {
  title: 'UI/Components/RadioList',
  component: RadioList,
  args: { options: people, onSelect: noop },
  parameters: { layout: `fullscreen`, screenshotsAt: [`desktop`] },
} satisfies Meta<typeof RadioList>;

export default meta;

type Story = StoryObj<typeof meta>;

export const Assortment: Story = {
  parameters: galleryParameters,
  render: () => (
    <StoryCanvas innerClassName="max-w-4xl">
      <StorySection
        title="States"
        contentClassName="grid items-start gap-8 sm:grid-cols-2"
      >
        <RadioList
          ariaLabel="Who will use this Mac?"
          options={people}
          selected="kara"
          onSelect={noop}
        />
        <RadioList
          ariaLabel="Relationship"
          options={[
            { value: `child`, label: `Your child` },
            { value: `peer`, label: `A spouse, friend, or peer` },
            {
              value: `self`,
              label: `Yourself`,
              disabled: true,
              disabledMessage: `Another protected person is already set to Myself.`,
            },
          ]}
          selected="child"
          onSelect={noop}
        />
      </StorySection>
    </StoryCanvas>
  ),
};
