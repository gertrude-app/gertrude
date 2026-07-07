import { Popover } from '@base-ui/react/popover';
import cx from 'clsx';
import { CalendarIcon } from 'lucide-react';
import React from 'react';
import Divider from '../primitives/Divider';
import HStack from '../primitives/HStack';
import Stack from '../primitives/Stack';
import Text from '../primitives/Text';
import Button from './Button';
import Input from './Input';
import { OverlayPortalProvider, useOverlayPortalContainer } from './OverlayPortalContext';
import Select from './Select';

interface CommonProps {
  label?: string;
  labelPostiion?: `left` | `top`;
  size?: `small` | `medium`;
  allowFuture?: boolean;
  allowPast?: boolean;
  className?: string;
}

type Props = CommonProps &
  (
    | {
        date: Date;
        setDate: (date: Date) => void;
        notRequred?: false;
      }
    | {
        date?: Date;
        setDate: (date: Date | undefined) => void;
        notRequred: true;
      }
  );

const monthOptions = [
  { value: `0`, label: `January` },
  { value: `1`, label: `February` },
  { value: `2`, label: `March` },
  { value: `3`, label: `April` },
  { value: `4`, label: `May` },
  { value: `5`, label: `June` },
  { value: `6`, label: `July` },
  { value: `7`, label: `August` },
  { value: `8`, label: `September` },
  { value: `9`, label: `October` },
  { value: `10`, label: `November` },
  { value: `11`, label: `December` },
] as const;

const weekdayLabels = [`Sun`, `Mon`, `Tue`, `Wed`, `Thu`, `Fri`, `Sat`] as const;

const formatDateTime = (date: Date): string =>
  new Intl.DateTimeFormat(`en`, {
    month: `short`,
    day: `numeric`,
    year: `numeric`,
    hour: `numeric`,
    minute: `2-digit`,
  }).format(date);

const formatTimeValue = (date: Date): string =>
  [date.getHours(), date.getMinutes()]
    .map((value) => String(value).padStart(2, `0`))
    .join(`:`);

const daysInMonth = (year: number, month: number): number =>
  new Date(year, month + 1, 0).getDate();

const isYearAvailable = (
  year: number,
  now: Date,
  allowPast: boolean,
  allowFuture: boolean,
): boolean => {
  const yearStart = new Date(year, 0, 1, 0, 0, 0, 0);
  const yearEnd = new Date(year, 11, 31, 23, 59, 59, 999);

  return (allowPast || yearEnd >= now) && (allowFuture || yearStart <= now);
};

const isMonthAvailable = (
  year: number,
  month: number,
  now: Date,
  allowPast: boolean,
  allowFuture: boolean,
): boolean => {
  const monthStart = new Date(year, month, 1, 0, 0, 0, 0);
  const monthEnd = new Date(year, month + 1, 0, 23, 59, 59, 999);

  return (allowPast || monthEnd >= now) && (allowFuture || monthStart <= now);
};

const isDayAvailable = (
  year: number,
  month: number,
  day: number,
  now: Date,
  allowPast: boolean,
  allowFuture: boolean,
): boolean => {
  const dayStart = new Date(year, month, day, 0, 0, 0, 0);
  const dayEnd = new Date(year, month, day, 23, 59, 59, 999);

  return (allowPast || dayEnd >= now) && (allowFuture || dayStart <= now);
};

const constrainDate = (
  date: Date,
  now: Date,
  allowPast: boolean,
  allowFuture: boolean,
): Date => {
  if (!allowPast && date < now) {
    return new Date(now);
  }

  if (!allowFuture && date > now) {
    return new Date(now);
  }

  return date;
};

const DateTimePicker: React.FC<Props> = (props) => {
  const {
    date,
    label,
    labelPostiion = `top`,
    size = `medium`,
    allowFuture = true,
    allowPast = true,
    className,
  } = props;
  const generatedId = React.useId();
  const now = new Date();
  const [viewDate, setViewDate] = React.useState(() =>
    constrainDate(date ?? now, now, allowPast, allowFuture),
  );
  const [popupContainer, setPopupContainer] = React.useState<HTMLElement | null>(null);
  const overlayPortalContainer = useOverlayPortalContainer();

  React.useEffect(() => {
    if (date) {
      setViewDate(constrainDate(date, new Date(), allowPast, allowFuture));
    }
  }, [date, allowPast, allowFuture]);

  const selectedYearNumber = viewDate.getFullYear();
  const selectedMonthNumber = viewDate.getMonth();
  const selectedMonth = String(
    selectedMonthNumber,
  ) as (typeof monthOptions)[number][`value`];
  const selectedYear = String(selectedYearNumber);
  const currentYear = now.getFullYear();
  const baseYear = isYearAvailable(selectedYearNumber, now, allowPast, allowFuture)
    ? selectedYearNumber
    : currentYear;
  const firstYear = allowPast ? baseYear - 4 : currentYear;
  const lastYear = allowFuture ? baseYear + 4 : currentYear;
  const yearOptions = Array.from({ length: lastYear - firstYear + 1 }, (_, index) =>
    String(firstYear + index),
  ).filter((year) => isYearAvailable(Number(year), now, allowPast, allowFuture));
  const availableMonthOptions = monthOptions.filter((month) =>
    isMonthAvailable(
      selectedYearNumber,
      Number(month.value),
      now,
      allowPast,
      allowFuture,
    ),
  );
  const daysInSelectedMonth = daysInMonth(selectedYearNumber, selectedMonthNumber);
  const firstDayOfMonth = new Date(selectedYearNumber, selectedMonthNumber, 1).getDay();
  const previousMonthDate = new Date(selectedYearNumber, selectedMonthNumber, 0);
  const previousMonthYear = previousMonthDate.getFullYear();
  const previousMonthNumber = previousMonthDate.getMonth();
  const previousMonthDayCount = previousMonthDate.getDate();
  const nextMonthDate = new Date(selectedYearNumber, selectedMonthNumber + 1, 1);
  const nextMonthYear = nextMonthDate.getFullYear();
  const nextMonthNumber = nextMonthDate.getMonth();
  const trailingDayCount = (7 - ((firstDayOfMonth + daysInSelectedMonth) % 7)) % 7;
  const calendarDays = [
    ...Array.from({ length: firstDayOfMonth }, (_, index) => ({
      year: previousMonthYear,
      month: previousMonthNumber,
      day: previousMonthDayCount - firstDayOfMonth + index + 1,
      adjacent: true,
    })),
    ...Array.from({ length: daysInSelectedMonth }, (_, index) => ({
      year: selectedYearNumber,
      month: selectedMonthNumber,
      day: index + 1,
      adjacent: false,
    })),
    ...Array.from({ length: trailingDayCount }, (_, index) => ({
      year: nextMonthYear,
      month: nextMonthNumber,
      day: index + 1,
      adjacent: true,
    })),
  ];

  const commitDate = (nextDate: Date): void => {
    const constrainedDate = constrainDate(nextDate, now, allowPast, allowFuture);

    setViewDate(constrainedDate);
    props.setDate(constrainedDate);
  };

  const setDateParts = (year: number, month: number): void => {
    const sourceDate = date ?? viewDate;
    const nextDate = new Date(sourceDate);
    const nextDay = Math.min(sourceDate.getDate(), daysInMonth(year, month));

    nextDate.setFullYear(year, month, nextDay);

    if (date || !props.notRequred) {
      commitDate(nextDate);
      return;
    }

    setViewDate(constrainDate(nextDate, now, allowPast, allowFuture));
  };

  const setDay = (year: number, month: number, day: number): void => {
    const nextDate = new Date(viewDate);

    nextDate.setFullYear(year, month, day);
    commitDate(nextDate);
  };

  const setTime = (time: string): void => {
    const [hours, minutes] = time.split(`:`).map(Number);

    if (
      hours === undefined ||
      minutes === undefined ||
      !Number.isFinite(hours) ||
      !Number.isFinite(minutes)
    ) {
      return;
    }

    const nextDate = new Date(date ?? viewDate);

    nextDate.setHours(hours, minutes, 0, 0);

    if (date || !props.notRequred) {
      commitDate(nextDate);
      return;
    }

    setViewDate(constrainDate(nextDate, now, allowPast, allowFuture));
  };

  const clearDate = (): void => {
    if (!props.notRequred) {
      return;
    }

    setViewDate(constrainDate(new Date(), now, allowPast, allowFuture));
    props.setDate(undefined);
  };

  return (
    <Stack
      direction={labelPostiion === `left` ? `horizontal` : `vertical`}
      gap={labelPostiion === `left` ? 2 : 1}
      align={labelPostiion === `left` ? `center` : `stretch`}
      className={className}
    >
      {label && (
        <Text
          as="label"
          htmlFor={generatedId}
          variant="label"
          className={cx(labelPostiion === `left` ? `shrink-0` : `ml-2.5`)}
        >
          {label}
        </Text>
      )}
      <Popover.Root modal={false}>
        <Popover.Trigger
          render={
            <button
              id={generatedId}
              type="button"
              className={cx(
                `relative flex w-full cursor-pointer items-stretch overflow-hidden border border-stone-300/80 bg-white text-left shadow shadow-stone-300/30 outline-none transition-[border-color,box-shadow] duration-150 select-none hover:border-stone-400/70 hover:shadow-stone-300/80 focus-visible:border-violet-300 focus-visible:shadow-violet-200/70 focus-visible:ring-2 focus-visible:ring-violet-200/70`,
                labelPostiion === `left` && `min-w-0 flex-1`,
                size === `small`
                  ? `min-h-[29.5px] rounded-[7px]`
                  : `min-h-[36.5px] rounded-[9px]`,
              )}
            >
              <span
                className={cx(
                  `flex min-w-0 flex-grow items-center bg-white text-stone-900`,
                  size === `small`
                    ? `gap-1.5 px-2 py-1 text-[13px]`
                    : `gap-2 px-2.5 py-1.25 text-[15px]`,
                )}
              >
                <span className={cx(`truncate`, !date && `text-stone-400`)}>
                  {date ? formatDateTime(date) : `Choose date...`}
                </span>
              </span>
              <span
                className={cx(
                  `flex shrink-0 items-center bg-white text-stone-400`,
                  size === `small` ? `px-2` : `px-2.5`,
                )}
              >
                <CalendarIcon className={size === `small` ? `h-3 w-3` : `h-4 w-4`} />
              </span>
            </button>
          }
        />
        <Popover.Portal container={overlayPortalContainer ?? undefined}>
          <Popover.Positioner sideOffset={4} align="center" className="z-[60]">
            <Popover.Popup
              ref={setPopupContainer}
              className="z-[60] mx-1 w-80 overflow-hidden rounded-xl border border-stone-200 bg-white shadow-md shadow-stone-300/50 outline-none select-none"
            >
              <Popover.Title className="sr-only">Choose date and time</Popover.Title>
              <OverlayPortalProvider container={popupContainer}>
                <div className="bg-stone-50 p-2">
                  <div className="grid grid-cols-[1fr_6rem] gap-2">
                    <Select
                      selected={selectedMonth}
                      setSelected={(month) =>
                        setDateParts(viewDate.getFullYear(), Number(month))
                      }
                      possibleValues={availableMonthOptions}
                      size="small"
                    />
                    <Select
                      selected={selectedYear}
                      setSelected={(year) =>
                        setDateParts(Number(year), viewDate.getMonth())
                      }
                      possibleValues={yearOptions}
                      size="small"
                    />
                  </div>
                </div>
                <Divider />
                <div className="bg-white p-2">
                  <div className="grid grid-cols-7 px-0.5">
                    {weekdayLabels.map((weekday) => (
                      <HStack key={weekday} justify="center" className="h-6">
                        <Text variant="label" className="text-[11px] !text-stone-400">
                          {weekday}
                        </Text>
                      </HStack>
                    ))}
                    {calendarDays.map(({ year, month, day, adjacent }) => {
                      const selected = date
                        ? year === date.getFullYear() &&
                          month === date.getMonth() &&
                          day === date.getDate()
                        : false;
                      const available = isDayAvailable(
                        year,
                        month,
                        day,
                        now,
                        allowPast,
                        allowFuture,
                      );

                      return (
                        <button
                          key={`${year}-${month}-${day}`}
                          type="button"
                          disabled={!available}
                          onClick={() => setDay(year, month, day)}
                          className={cx(
                            `flex h-8 items-center justify-center rounded-lg text-sm outline-none transition`,
                            selected
                              ? `bg-violet-500 text-white`
                              : available
                                ? adjacent
                                  ? `cursor-pointer text-stone-400 hover:bg-stone-100 hover:text-stone-500 focus-visible:ring-2 focus-visible:ring-violet-200`
                                  : `cursor-pointer text-stone-700 hover:bg-stone-100 focus-visible:ring-2 focus-visible:ring-violet-200`
                                : adjacent
                                  ? `cursor-not-allowed text-stone-200`
                                  : `cursor-not-allowed text-stone-300`,
                          )}
                        >
                          {day}
                        </button>
                      );
                    })}
                  </div>
                </div>
                <Divider />
                <div className="bg-stone-50 p-2">
                  <HStack gap={2}>
                    <Input
                      type="time"
                      value={formatTimeValue(date ?? viewDate)}
                      setValue={setTime}
                      className="min-w-0 flex-1"
                    />
                    {props.notRequred && date ? (
                      <Button type="button" onClick={clearDate}>
                        Clear
                      </Button>
                    ) : null}
                  </HStack>
                </div>
              </OverlayPortalProvider>
            </Popover.Popup>
          </Popover.Positioner>
        </Popover.Portal>
      </Popover.Root>
    </Stack>
  );
};

export default DateTimePicker;
