import React from 'react';
import TextInput from '../../../TextInput';
import UserInputText from '../../Keychains/Keys/KeyCreator/UserInputText';
import SelectMenu from '../../SelectMenu';

type Props = {
  username: string;
  timeRequested: string;
  requestComment?: string;
  requestedDurationInSeconds: number;
  durationInSeconds: string;
  customDurationInMinutes?: string;
  responseComment: string;
  setResponseComment(comment: string): unknown;
  setDuration(duration: string): unknown;
  setCustomDuration(duration: string): unknown;
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
}) => (
  <div className="mt-4 text-lg">
    <div>
      User <UserInputText small>{username}</UserInputText> requested a filter suspension
      for{' '}
      <UserInputText small>{Math.floor(requestedDurationInSeconds / 60)}</UserInputText>{' '}
      minutes
      {requestComment ? `, with the comment:` : `.`}
    </div>
    {requestComment && (
      <div className="mt-4">
        <UserInputText>&ldquo;{requestComment}&rdquo;</UserInputText>
      </div>
    )}
    <hr className="mt-6 opacity-50" />
    <form className="mt-4 space-y-5 mb-2">
      <SelectMenu
        label="Duration:"
        options={DURATION_OPTS}
        selectedOption={durationInSeconds}
        setSelected={setDuration}
        deemphasized
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
      />
    </form>
  </div>
);

export default SuspendFilterRequestForm;

const DURATION_OPTS = [
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
