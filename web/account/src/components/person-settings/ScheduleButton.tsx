import { Button, Divider, DropdownMenu, HStack, Input, Text, VStack } from '@gertrude/ui';
import cx from 'clsx';
import { ClockIcon } from 'lucide-react';
import React from 'react';
import type { Schedule } from '#/components/types';
import {
  dayEntries,
  formatSchedule,
  inputValueToTimeOfDay,
  timeOfDayToInputValue,
} from '#/components/utils';

export type ScheduleButtonProps = {
  schedule?: Schedule;
  setSchedule: (schedule?: Schedule) => void;
};

type DayKey = keyof Schedule[`days`];

export const defaultSchedule: Schedule = {
  type: `active`,
  days: {
    sunday: false,
    monday: true,
    tuesday: true,
    wednesday: true,
    thursday: true,
    friday: true,
    saturday: false,
  },
  startTime: { hour: 8, minute: 0 },
  endTime: { hour: 16, minute: 0 },
};

export const ScheduleEditor: React.FC<ScheduleButtonProps> = ({
  schedule,
  setSchedule,
}) => {
  const editableSchedule = schedule ?? defaultSchedule;
  const selectedDayCount = dayEntries.filter(
    ([day]) => editableSchedule.days[day],
  ).length;
  const updateSchedule = (patch: Partial<Schedule>): void => {
    setSchedule({ ...editableSchedule, ...patch });
  };
  const updateDay = (day: DayKey): void => {
    if (editableSchedule.days[day] && selectedDayCount === 1) {
      return;
    }

    updateSchedule({
      days: { ...editableSchedule.days, [day]: !editableSchedule.days[day] },
    });
  };
  const updateTime = (field: `startTime` | `endTime`, value: string): void => {
    const time = inputValueToTimeOfDay(value);

    if (!time) {
      return;
    }

    updateSchedule(field === `startTime` ? { startTime: time } : { endTime: time });
  };

  return (
    <VStack
      gap={3}
      className="p-2"
      onClick={(event) => event.stopPropagation()}
      onKeyDown={(event) => event.stopPropagation()}
    >
      <VStack gap={1}>
        <div className="grid grid-cols-2 rounded-lg bg-stone-100 p-1">
          {([`active`, `inactive`] as const).map((type) => (
            <button
              key={type}
              type="button"
              onClick={() => updateSchedule({ type })}
              className={cx(
                `rounded-md px-2 py-1 text-sm font-medium transition-colors cursor-pointer border`,
                editableSchedule.type === type
                  ? `bg-white text-stone-900 shadow shadow-stone-300/40 border-stone-200`
                  : `text-stone-600 hover:bg-stone-200/70 border-transparent`,
              )}
            >
              {type === `active` ? `Active` : `Inactive`}
            </button>
          ))}
        </div>
      </VStack>
      <div className="grid grid-cols-7 gap-1">
        {dayEntries.map(([day, label]) => {
          const selected = editableSchedule.days[day];
          const onlySelectedDay = selected && selectedDayCount === 1;

          return (
            <button
              key={day}
              type="button"
              aria-pressed={selected}
              disabled={onlySelectedDay}
              onClick={() => updateDay(day)}
              className={cx(
                `rounded-md border px-1.5 py-1 text-xs font-medium transition-colors`,
                onlySelectedDay ? `cursor-not-allowed` : `cursor-pointer`,
                selected
                  ? `border-violet-300 bg-violet-100 text-violet-900`
                  : `border-stone-200 bg-white text-stone-500 hover:bg-stone-100`,
              )}
            >
              {label}
            </button>
          );
        })}
      </div>
      <HStack gap={2}>
        <Input
          type="time"
          value={timeOfDayToInputValue(editableSchedule.startTime)}
          setValue={(value) => updateTime(`startTime`, value)}
          className="flex-grow"
        />
        <Text variant="bodyMuted">to</Text>
        <Input
          type="time"
          value={timeOfDayToInputValue(editableSchedule.endTime)}
          setValue={(value) => updateTime(`endTime`, value)}
          className="flex-grow"
        />
      </HStack>
      <Divider />
      <HStack justify="between" gap={3}>
        <Text variant="captionMuted" className="min-w-0">
          {formatSchedule(editableSchedule)}
        </Text>
        {schedule && (
          <Button
            type="button"
            onClick={() => setSchedule(undefined)}
            size="small"
            variant="ghost"
          >
            Clear
          </Button>
        )}
      </HStack>
    </VStack>
  );
};

const ScheduleButton: React.FC<ScheduleButtonProps> = ({ schedule, setSchedule }) => (
  <DropdownMenu
    contentClassName="w-82"
    trigger={
      <Button type="button" onClick={() => {}} size="small" icon={ClockIcon}>
        {schedule ? `Schedule` : `No Schedule`}
      </Button>
    }
  >
    <ScheduleEditor schedule={schedule} setSchedule={setSchedule} />
  </DropdownMenu>
);

export default ScheduleButton;
