import React from 'react';
import { capitalize } from '@dash/utils';
import * as date from '@dash/datetime';
import { TextInput, SelectMenu } from '@shared/components';
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
}) => (
  <div className="mt-5 sm:px-2 text-lg">
    <div className="leading-tight text-gray-700">
      {date.isOlderThan(requestedAt, { minutes: 5 }) ? (
        <>
          <UserInputText small>
            {capitalize(date.relativeTime(new Date(requestedAt)))}
          </UserInputText>
          {` `}user
        </>
      ) : (
        `User`
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
        <UserInputText className="text-center text-gray-700">
          &ldquo;{requestComment}&rdquo;
        </UserInputText>
      </div>
    )}
    <hr className="mt-6 opacity-50" />
    <form className="mt-4 space-y-5 mb-2">
      <SelectMenu
        label="Granted duration:"
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
);

export default SuspendFilterRequestForm;

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
