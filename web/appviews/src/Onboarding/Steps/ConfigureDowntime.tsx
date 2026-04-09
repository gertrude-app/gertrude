import cx from 'classnames';
import React, { useContext, useState } from 'react';
import type { PlainTime } from '../onboarding-store';
import OnboardingContext from '../OnboardingContext';
import * as Onboarding from '../UtilityComponents';

const ConfigureDowntime: React.FC = () => {
  const { emit } = useContext(OnboardingContext);
  const [showConfigModal, setShowConfigModal] = useState(false);
  const [start, setStart] = useState<PlainTime>({ hour: 21, minute: 0 });
  const [end, setEnd] = useState<PlainTime>({ hour: 5, minute: 0 });
  const [saved, setSaved] = useState(false);
  return (
    <Onboarding.Centered>
      <DowntimeConfigModal
        open={showConfigModal}
        onClose={() => setShowConfigModal(false)}
        start={start}
        setStart={setStart}
        end={end}
        setEnd={setEnd}
        onSave={() => {
          setSaved(true);
          setShowConfigModal(false);
          emit({ case: `setDowntimeSchedule`, window: { start, end } });
        }}
      />
      <div className="w-14 h-14 bg-violet-100 rounded-2xl flex items-center justify-center mb-5">
        <i className="fa-solid fa-moon text-2xl text-violet-500" />
      </div>
      <Onboarding.Heading centered>Set up downtime?</Onboarding.Heading>
      <Onboarding.Text centered className="mt-3 mb-6 max-w-lg">
        Downtime blocks <b>all internet access</b> during a daily window&mdash;like
        nighttime hours. This can also be set up later from the parents website.
      </Onboarding.Text>
      {saved && (
        <div className="flex items-center gap-2 bg-emerald-50 border border-emerald-200 text-emerald-700 rounded-xl px-4 py-2 mb-4 text-sm font-medium">
          <i className="fa-solid fa-check" />
          Downtime set: {formatTime(start)} &ndash; {formatTime(end)}
        </div>
      )}
      <Onboarding.ButtonGroup
        direction="column"
        primary={saved ? `Continue` : `Skip for now`}
        secondary={{
          text: saved ? `Edit downtime` : `Set up downtime`,
          icon: `fa-solid fa-clock`,
          onClick: () => setShowConfigModal(true),
        }}
      />
    </Onboarding.Centered>
  );
};

export default ConfigureDowntime;

interface DowntimeConfigModalProps {
  open: boolean;
  onClose(): void;
  start: PlainTime;
  setStart(time: PlainTime): void;
  end: PlainTime;
  setEnd(time: PlainTime): void;
  onSave(): void;
}

const DowntimeConfigModal: React.FC<DowntimeConfigModalProps> = ({
  open,
  onClose,
  start,
  setStart,
  end,
  setEnd,
  onSave,
}) => (
  <div
    onClick={onClose}
    className={cx(
      `absolute left-0 top-0 w-full h-full bg-black/50 z-40 transition-[opacity,backdrop-filter] duration-300 flex justify-center items-center p-12`,
      open ? `opacity-100 backdrop-blur` : `opacity-0 pointer-events-none`,
    )}
  >
    <div
      className={cx(
        `bg-white rounded-3xl transition-[opacity,transform] duration-500 w-full max-w-md`,
        open ? `opacity-100` : `opacity-0 translate-y-8`,
      )}
      onClick={(e) => e.stopPropagation()}
    >
      <div className="p-8 pb-6">
        <div className="mt-6 flex flex-col items-center gap-3">
          <span className="text-slate-500 font-medium text-md">
            Block all internet between:
          </span>
          <TimePicker time={start} setTime={setStart} />
          <span className="text-slate-500 font-medium text-md">and</span>
          <TimePicker time={end} setTime={setEnd} />
        </div>
      </div>
      <div className="flex justify-end gap-3 p-4 pt-4 rounded-b-3xl">
        <button
          onClick={onClose}
          className="px-4 py-2 text-slate-500 hover:text-slate-700 font-medium rounded-xl transition-colors duration-200"
          tabIndex={-1}
        >
          Cancel
        </button>
        <button
          onClick={onSave}
          className="px-5 py-2 bg-violet-500 hover:bg-violet-600 text-white font-medium rounded-xl transition-colors duration-200"
          tabIndex={-1}
        >
          Save downtime
        </button>
      </div>
    </div>
  </div>
);

interface TimePickerProps {
  time: PlainTime;
  setTime(time: PlainTime): void;
}

const TimePicker: React.FC<TimePickerProps> = ({ time, setTime }) => {
  const displayHour = time.hour > 12 ? time.hour - 12 : time.hour || 12;
  const isPm = time.hour >= 12;
  return (
    <div className="flex items-center gap-1.5">
      <div className="flex items-center gap-0.5">
        <TimeButton
          onClick={() => setTime({ ...time, hour: time.hour === 23 ? 0 : time.hour + 1 })}
          icon="fa-solid fa-chevron-up"
        />
        <span className="w-8 text-center text-xl font-mono font-medium text-slate-800">
          {displayHour}
        </span>
        <TimeButton
          onClick={() => setTime({ ...time, hour: time.hour === 0 ? 23 : time.hour - 1 })}
          icon="fa-solid fa-chevron-down"
        />
      </div>
      <span className="text-xl font-mono font-medium text-slate-400">:</span>
      <div className="flex items-center gap-0.5">
        <TimeButton
          onClick={() => {
            if (time.minute === 59) {
              setTime({ hour: time.hour === 23 ? 0 : time.hour + 1, minute: 0 });
            } else {
              setTime({ ...time, minute: time.minute + 1 });
            }
          }}
          icon="fa-solid fa-chevron-up"
        />
        <span className="w-8 text-center text-xl font-mono font-medium text-slate-800">
          {String(time.minute).padStart(2, `0`)}
        </span>
        <TimeButton
          onClick={() => {
            if (time.minute === 0) {
              setTime({ hour: time.hour === 0 ? 23 : time.hour - 1, minute: 59 });
            } else {
              setTime({ ...time, minute: time.minute - 1 });
            }
          }}
          icon="fa-solid fa-chevron-down"
        />
      </div>
      <button
        onClick={() => setTime({ ...time, hour: isPm ? time.hour - 12 : time.hour + 12 })}
        className="ml-2 w-10 h-8 rounded-full bg-slate-100 hover:bg-slate-200 active:bg-violet-200 flex justify-center items-center transition-[background-color,transform] duration-200 active:scale-90"
        tabIndex={-1}
      >
        <span className="font-semibold text-slate-500 text-xs uppercase">
          {isPm ? `pm` : `am`}
        </span>
      </button>
    </div>
  );
};

const TimeButton: React.FC<{ onClick(): void; icon: string }> = ({ onClick, icon }) => (
  <button
    onClick={onClick}
    className="w-5 h-5 rounded-full bg-slate-100 hover:bg-slate-200 active:bg-violet-200 active:text-violet-600 flex justify-center items-center transition-[background-color,transform,color] duration-200 active:scale-90 text-slate-400"
    tabIndex={-1}
  >
    <i className={cx(icon, `text-[9px]`)} />
  </button>
);

function formatTime(time: PlainTime): string {
  const hour = time.hour > 12 ? time.hour - 12 : time.hour || 12;
  const minute = String(time.minute).padStart(2, `0`);
  const period = time.hour >= 12 ? `PM` : `AM`;
  return `${hour}:${minute} ${period}`;
}
