import React from 'react';
import type { Meta, StoryObj } from '@storybook/tanstack-react';
import type { FC } from 'react';
import DateTimePicker from './DateTimePicker';
import { StoryCanvas, StorySection, galleryParameters } from '#/storybook/StoryLayout';

const makeDate = (dayOffset: number, hour: number, minute: number): Date => {
  const date = new Date();

  date.setDate(date.getDate() + dayOffset);
  date.setHours(hour, minute, 0, 0);

  return date;
};

const DateTimePickerAssortment: FC = () => {
  const [schoolStart, setSchoolStart] = React.useState(() => makeDate(7, 8, 30));
  const [quietHours, setQuietHours] = React.useState(() => makeDate(1, 20, 0));
  const [weekendReview, setWeekendReview] = React.useState(() => makeDate(4, 10, 15));
  const [oneTimePass, setOneTimePass] = React.useState(() => makeDate(2, 16, 45));
  const [pastOnly, setPastOnly] = React.useState(() => makeDate(-7, 8, 30));
  const [futureOnly, setFutureOnly] = React.useState(() => makeDate(7, 8, 30));
  const [optional, setOptional] = React.useState<Date | undefined>();

  return (
    <StoryCanvas innerClassName="max-w-3xl">
      <StorySection
        title="Common pickers"
        contentClassName="grid items-end gap-5 sm:grid-cols-2"
      >
        <DateTimePicker label="Medium" date={schoolStart} setDate={setSchoolStart} />
        <DateTimePicker
          label="Small"
          date={quietHours}
          setDate={setQuietHours}
          size="small"
        />
        <DateTimePicker
          label="Left label"
          labelPostiion="left"
          date={weekendReview}
          setDate={setWeekendReview}
        />
        <DateTimePicker date={oneTimePass} setDate={setOneTimePass} />
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
        />
        <DateTimePicker
          label="Future only"
          date={futureOnly}
          setDate={setFutureOnly}
          allowPast={false}
        />
        <DateTimePicker
          label="Optional"
          date={optional}
          setDate={setOptional}
          notRequred
        />
      </StorySection>
    </StoryCanvas>
  );
};

const meta = {
  title: 'UI/DateTimePicker',
  component: DateTimePicker,
  args: {
    date: makeDate(2, 16, 45),
    setDate: () => undefined,
    notRequred: false,
  },
  parameters: { layout: `fullscreen` },
} satisfies Meta<typeof DateTimePicker>;

export default meta;

type Story = StoryObj<typeof meta>;

export const Assortment: Story = {
  parameters: galleryParameters,
  render: () => <DateTimePickerAssortment />,
};
