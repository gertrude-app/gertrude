import React from 'react';
import type { Meta, StoryObj } from '@storybook/tanstack-react';
import type { FC } from 'react';
import DateTimePicker from './DateTimePicker';
import { StoryCanvas, StorySection, galleryParameters } from '#/storybook/StoryLayout';

const fixedNow = new Date(2026, 6, 7, 12, 0, 0, 0);

const makeDate = (day: number, hour: number, minute: number): Date =>
  new Date(2026, 6, day, hour, minute, 0, 0);

const DateTimePickerAssortment: FC = () => {
  const [schoolStart, setSchoolStart] = React.useState(() => makeDate(14, 8, 30));
  const [quietHours, setQuietHours] = React.useState(() => makeDate(8, 20, 0));
  const [weekendReview, setWeekendReview] = React.useState(() => makeDate(11, 10, 15));
  const [oneTimePass, setOneTimePass] = React.useState(() => makeDate(9, 16, 45));
  const [pastOnly, setPastOnly] = React.useState(() => makeDate(3, 8, 30));
  const [futureOnly, setFutureOnly] = React.useState(() => makeDate(14, 8, 30));
  const [optional, setOptional] = React.useState<Date | undefined>();

  return (
    <StoryCanvas innerClassName="max-w-3xl">
      <StorySection
        title="Common pickers"
        contentClassName="grid items-end gap-5 sm:grid-cols-2"
      >
        <DateTimePicker
          label="Medium"
          date={schoolStart}
          setDate={setSchoolStart}
          now={fixedNow}
        />
        <DateTimePicker
          label="Small"
          date={quietHours}
          setDate={setQuietHours}
          size="small"
          now={fixedNow}
        />
        <DateTimePicker
          label="Left label"
          labelPosition="left"
          date={weekendReview}
          setDate={setWeekendReview}
          now={fixedNow}
        />
        <DateTimePicker date={oneTimePass} setDate={setOneTimePass} now={fixedNow} />
      </StorySection>
      <StorySection
        title="Date constraints"
        contentClassName="grid items-end gap-5 sm:grid-cols-2"
      >
        <DateTimePicker
          label="Past only"
          date={pastOnly}
          setDate={setPastOnly}
          allowFuture={false}
          now={fixedNow}
        />
        <DateTimePicker
          label="Future only"
          date={futureOnly}
          setDate={setFutureOnly}
          allowPast={false}
          now={fixedNow}
        />
        <DateTimePicker
          label="Optional"
          date={optional}
          setDate={setOptional}
          notRequired
          now={fixedNow}
        />
      </StorySection>
    </StoryCanvas>
  );
};

const meta = {
  title: 'UI/Components/DateTimePicker',
  component: DateTimePicker,
  args: {
    date: makeDate(9, 16, 45),
    setDate: () => undefined,
    notRequired: false,
    now: fixedNow,
  },
  argTypes: {
    now: { control: false },
    open: { control: false },
    defaultOpen: { control: false },
    onOpenChange: { control: false },
  },
  parameters: { layout: `fullscreen` },
} satisfies Meta<typeof DateTimePicker>;

export default meta;

type Story = StoryObj<typeof meta>;

export const Assortment: Story = {
  parameters: { ...galleryParameters, screenshotsAt: [`desktop`] },
  render: () => <DateTimePickerAssortment />,
};

export const OpenCalendar: Story = {
  parameters: { ...galleryParameters, screenshotsAt: [`desktop`] },
  render: () => (
    <StoryCanvas innerClassName="max-w-xl">
      <StorySection title="Open calendar" contentClassName="block pb-96">
        <DateTimePicker
          open
          label="Expiration date"
          date={makeDate(14, 8, 30)}
          setDate={() => undefined}
          now={fixedNow}
        />
      </StorySection>
    </StoryCanvas>
  ),
};
