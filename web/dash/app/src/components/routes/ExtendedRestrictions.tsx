import { ChevronDownIcon } from '@heroicons/react/20/solid';
import { Toggle } from '@shared/components';
import cx from 'classnames';
import React from 'react';
import type {
  ExtControlsState,
  RestrictionControl,
  RestrictionGroup,
} from '../../lib/extendedRestrictions';
import type { Action } from '../../reducers/ios-device-reducer';
import {
  EXTENDED_RESTRICTION_GROUPS,
  SOFTWARE_UPDATE_DELAY_DEFAULT,
  SOFTWARE_UPDATE_DELAY_MAX,
  SOFTWARE_UPDATE_DELAY_MIN,
  controlOffValues,
  controlOnValues,
  groupValues,
  isControlOn,
} from '../../lib/extendedRestrictions';

interface Props {
  extended: ExtControlsState;
  dispatch: React.Dispatch<Action>;
}

const ExtendedRestrictions: React.FC<Props> = ({ extended, dispatch }) => (
  <>
    {EXTENDED_RESTRICTION_GROUPS.map((group) => (
      <RestrictionGroupCard
        key={group.id}
        group={group}
        extended={extended}
        dispatch={dispatch}
      />
    ))}
  </>
);

const RestrictionGroupCard: React.FC<{
  group: RestrictionGroup;
  extended: ExtControlsState;
  dispatch: React.Dispatch<Action>;
}> = ({ group, extended, dispatch }) => {
  const onCount = group.controls.filter((c) => isControlOn(extended, c)).length;
  const total = group.controls.length;
  const anyOn = onCount > 0;
  const partial = onCount > 0 && onCount < total;
  const [manualExpanded, setManualExpanded] = React.useState<boolean | null>(null);
  const expanded = manualExpanded ?? partial;

  return (
    <div className="mt-3 rounded-xl bg-slate-100 border border-transparent">
      <div className="flex items-center justify-between gap-4 p-4 sm:p-6">
        <button
          type="button"
          className="flex items-start gap-3 text-left flex-1 min-w-0"
          onClick={() => setManualExpanded(!expanded)}
        >
          <ChevronDownIcon
            className={cx(
              `w-5 h-5 mt-0.5 shrink-0 text-slate-400 transition-transform`,
              expanded ? `rotate-0` : `-rotate-90`,
            )}
          />
          <span className="min-w-0">
            <span className="block font-medium text-slate-700 leading-tight">
              {group.title}
            </span>
            <span className="block text-slate-500 text-sm mt-1">{group.description}</span>
          </span>
        </button>
        <div className="flex items-center gap-3 shrink-0">
          {anyOn && (
            <span className="text-xs font-medium px-2 py-0.5 rounded-full bg-violet-100 text-violet-700">
              {onCount} of {total}
            </span>
          )}
          <Toggle
            enabled={anyOn}
            setEnabled={(on) =>
              dispatch({ type: `setExtendedControls`, values: groupValues(group, on) })
            }
          />
        </div>
      </div>
      {expanded && (
        <div className="px-4 sm:px-6 pb-4 sm:pb-6">
          <div className="flex flex-col gap-3 border-t border-slate-200 pt-4">
            {group.controls.map((control) => (
              <ControlRow
                key={control.field}
                control={control}
                extended={extended}
                dispatch={dispatch}
              />
            ))}
          </div>
        </div>
      )}
    </div>
  );
};

const ControlRow: React.FC<{
  control: RestrictionControl;
  extended: ExtControlsState;
  dispatch: React.Dispatch<Action>;
}> = ({ control, extended, dispatch }) => {
  const on = isControlOn(extended, control);
  const stateWord = on ? (control.onWord ?? `Blocked`) : (control.offWord ?? `Allowed`);
  return (
    <div>
      <div className="flex items-center justify-between gap-4">
        <div className="min-w-0">
          <span className="block text-sm font-medium text-slate-700">
            {control.label}
          </span>
          {control.hint && (
            <span className="block text-xs text-slate-400 mt-0.5">{control.hint}</span>
          )}
        </div>
        <div className="flex items-center gap-2.5 shrink-0">
          <span
            className={cx(
              `text-xs font-medium w-16 text-right`,
              on ? `text-violet-700` : `text-slate-400`,
            )}
          >
            {stateWord}
          </span>
          <Toggle
            small
            enabled={on}
            setEnabled={(value) =>
              dispatch({
                type: `setExtendedControls`,
                values: value ? controlOnValues(control) : controlOffValues(control),
              })
            }
          />
        </div>
      </div>
      {control.delayDays && on && (
        <div className="flex items-center gap-2 mt-2">
          <span className="text-sm text-slate-500">Delay for</span>
          <input
            type="number"
            min={SOFTWARE_UPDATE_DELAY_MIN}
            max={SOFTWARE_UPDATE_DELAY_MAX}
            value={extended.enforcedSoftwareUpdateDelay ?? SOFTWARE_UPDATE_DELAY_DEFAULT}
            onChange={(e) =>
              dispatch({
                type: `setExtendedControls`,
                values: { enforcedSoftwareUpdateDelay: clampDelay(e.target.value) },
              })
            }
            className="w-20 border border-slate-300 rounded-lg px-3 py-1.5 focus:outline-none focus:ring-2 focus:ring-violet-300"
          />
          <span className="text-sm text-slate-500">days after release</span>
        </div>
      )}
    </div>
  );
};

function clampDelay(raw: string): number {
  const parsed = parseInt(raw, 10);
  if (Number.isNaN(parsed)) {
    return SOFTWARE_UPDATE_DELAY_DEFAULT;
  }
  return Math.min(SOFTWARE_UPDATE_DELAY_MAX, Math.max(SOFTWARE_UPDATE_DELAY_MIN, parsed));
}

export default ExtendedRestrictions;
