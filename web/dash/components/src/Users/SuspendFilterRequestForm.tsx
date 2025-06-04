import * as date from '@dash/datetime';
import { SelectMenu, TextInput } from '@shared/components';
import { capitalize } from '@shared/string';
import React from 'react';
import UserInputText from '../UserInputText';

type Props = {
  username: string;
  requestComment?: string;
  requestedDurationInSeconds: number;
  durationInSeconds: string;
  customDurationInMinutes?: string;
  responseComment: string;
  setResponseComment(comment: string): unknown;
  setDuration(duration: string): unknown;
  setCustomDuration(duration: string): unknown;
  requestedAt: string;
  extraMonitoringOptions: Record<string, string>;
  selectedExtraMonitoringOption?: string;
  setSelectedExtraMonitoringOption(option: string): unknown;
};

const SuspendFilterRequestForm: React.FC<Props> = ({
  username,
  requestedDurationInSeconds,
  requestComment,
  durationInSeconds,
  setDuration,
  responseComment,
  setResponseComment,
  customDurationInMinutes,
  setCustomDuration,
  requestedAt,
  extraMonitoringOptions,
  selectedExtraMonitoringOption,
  setSelectedExtraMonitoringOption,
}) => (
  <div className="mt-5 sm:px-2 text-lg flex flex-col">
    <div className="text-slate-700">
      {date.isOlderThan(requestedAt, { minutes: 5 }) ? (
        <>
          <UserInputText small>
            {capitalize(date.relativeTime(new Date(requestedAt)))}
          </UserInputText>
          {` `}child
        </>
      ) : (
        `Child`
      )}
      {` `}
      <UserInputText small>{username}</UserInputText> requested a filter suspension for
      {` `}
      <UserInputText small>{Math.floor(requestedDurationInSeconds / 60)}</UserInputText>
      {` `}
      minutes
      {requestComment ? `, with the comment:` : `.`}
    </div>
    {requestComment && (
      <div className="mt-4 flex justify-center">
        <UserInputText className="text-center text-slate-700">
          &ldquo;{requestComment}&rdquo;
        </UserInputText>
      </div>
    )}
    <hr className="mt-6 opacity-50" />
    <div className="flex justify-center">
      <form className="mt-4 space-y-5 mb-2 max-w-2xl flex-grow">
        <SelectMenu
          label="Duration:"
          testId="select-suspension-duration"
          options={DURATION_OPTS}
          selectedOption={durationInSeconds}
          setSelected={setDuration}
        />
        {durationInSeconds === `custom` && (
          <TextInput
            type="positiveInteger"
            label="Custom duration (minutes):"
            value={customDurationInMinutes ?? ``}
            setValue={setCustomDuration}
          />
        )}
        {Object.values(extraMonitoringOptions).length > 0 && (
          <SelectMenu
            label="Extra monitoring:"
            testId="select-extra-monitoring-option"
            options={[
              { value: `off`, display: `off` },
              ...Object.entries(extraMonitoringOptions)
                .sort(([a], [b]) => sortExtraMonitoringOpts(a, b))
                .map(([value, display]) => ({ value, display })),
            ]}
            selectedOption={selectedExtraMonitoringOption ?? `off`}
            setSelected={setSelectedExtraMonitoringOption}
          />
        )}
        <TextInput
          label="Your comment:"
          type="textarea"
          optional
          value={responseComment}
          setValue={setResponseComment}
          testId="suspend-filter-req-comment"
        />
      </form>
    </div>
  </div>
);

export default SuspendFilterRequestForm;

export function sortExtraMonitoringOpts(a: string, b: string): number {
  if (a === b) {
    return 0;
  } else if (b === `k`) {
    return a.includes(`k`) ? 1 : -1;
  } else if (a === `k`) {
    return b.includes(`k`) ? -1 : 1;
  } else if (a.includes(`k`) && !b.includes(`k`)) {
    return 1;
  } else if (b.includes(`k`) && !a.includes(`k`)) {
    return -1;
  } else {
    const matchA = a.match(/@(\d+)/);
    const matchB = b.match(/@(\d+)/);
    if (matchA && matchB) {
      const numA = Number(matchA[1]);
      const numB = Number(matchB[1]);
      return numA === numB ? 0 : numA < numB ? -1 : 1;
    } else {
      return a === b ? 0 : a < b ? -1 : 1;
    }
  }
}

export const DURATION_OPTS = [
  { value: `180`, display: `3 minutes` },
  { value: `300`, display: `5 minutes` },
  { value: `600`, display: `10 minutes` },
  { value: `1200`, display: `20 minutes` },
  { value: `1800`, display: `30 minutes` },
  { value: `3600`, display: `1 hour` },
  { value: `5400`, display: `1.5 hours` },
  { value: `7200`, display: `2 hours` },
  { value: `custom`, display: `custom duration...` },
];
