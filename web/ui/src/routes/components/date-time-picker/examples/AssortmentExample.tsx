import React, { useState } from 'react';
import DateTimePicker from '#/components/ui/DateTimePicker';

const makeDate = (dayOffset: number, hour: number, minute: number): Date => {
  const date = new Date();

  date.setDate(date.getDate() + dayOffset);
  date.setHours(hour, minute, 0, 0);

  return date;
};

const AssortmentExample: React.FC = () => {
  const [schoolStart, setSchoolStart] = useState(() => makeDate(7, 8, 30));
  const [quietHours, setQuietHours] = useState(() => makeDate(1, 20, 0));
  const [weekendReview, setWeekendReview] = useState(() => makeDate(4, 10, 15));
  const [oneTimePass, setOneTimePass] = useState(() => makeDate(2, 16, 45));
  const [pastOnly, setPastOnly] = useState(() => makeDate(-7, 8, 30));
  const [futureOnly, setFutureOnly] = useState(() => makeDate(7, 8, 30));
  const [optional, setOptional] = useState<Date | undefined>();

  return (
    <div className="grid h-full place-items-center p-8">
      <div className="grid w-full max-w-xl items-end gap-5 sm:grid-cols-2">
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
      </div>
    </div>
  );
};

export default AssortmentExample;
