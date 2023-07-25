import React from 'react';
import { TextInput, Button, SelectMenu } from '@shared/components';
import type {
  PendingNotificationMethod,
  NewAdminNotificationMethodEvent as Event,
  CreatePendingNotificationMethod,
} from '@dash/types';

type Props = PendingNotificationMethod & {
  onEvent(event: Event): unknown;
};

const EditNotificationSidebar: React.FC<Props> = ({
  onEvent,
  sendCodeRequest,
  confirmationRequest,
  confirmationCode,
  ...props
}) => (
  <div className="p-8 flex flex-col grow h-full">
    <h2 className="text-2xl font-black text-slate-700 mb-8">New notification method</h2>
    <div className="flex flex-col space-y-6">
      <SelectMenu
        label="Method:"
        options={[
          { value: `email`, display: `Email` },
          { value: `text`, display: `Text` },
          { value: `slack`, display: `Slack` },
        ]}
        selectedOption={props.case}
        setSelected={(methodType) => onEvent({ type: `methodTypeUpdated`, methodType })}
      />
      {props.case === `email` ? (
        <TextInput
          key="email"
          type="email"
          value={props.email}
          setValue={(email) => onEvent({ type: `emailAddressUpdated`, email })}
          label="Email address:"
          required
        />
      ) : props.case === `text` ? (
        <TextInput
          key="text"
          label="Phone number:"
          type="text"
          required
          value={props.phoneNumber}
          setValue={(phoneNumber) =>
            onEvent({ type: `textPhoneNumberUpdated`, phoneNumber })
          }
        />
      ) : (
        <>
          <TextInput
            key="text"
            label="Channel name:"
            type="text"
            required
            value={props.channelName}
            setValue={(channelName) =>
              onEvent({ type: `slackChannelNameUpdated`, channelName })
            }
          />
          <TextInput
            label="Channel ID:"
            type="text"
            required
            value={props.channelId}
            setValue={(channelId) =>
              onEvent({ type: `slackChannelIdUpdated`, channelId })
            }
          />
          <TextInput
            label="Bot token:"
            type="text"
            placeholder="xoxb-xxxxxxxxxx-xxxxxxxxxx-xxxxxxxxxx-xxxxxxxxxx"
            required
            value={props.token}
            setValue={(token) => onEvent({ type: `slackTokenUpdated`, token })}
          />
        </>
      )}
    </div>
    <div className="flex flex-col mt-3">
      {sendCodeRequest.state !== `succeeded` ? (
        <Button
          type="button"
          onClick={() => onEvent({ type: `sendCodeClicked` })}
          color="secondary"
          disabled={!methodValid(props) || sendCodeRequest.state === `ongoing`}
          className="self-end mt-4"
        >
          {sendCodeRequest.state === `ongoing` ? `Sending...` : `Send verification code`}
        </Button>
      ) : (
        <>
          <TextInput
            className="mt-8 pt-8 border-t border-slate-200/50"
            label="Enter 6-digit code:"
            type="text"
            value={confirmationCode}
            disabled={confirmationRequest.state === `ongoing`}
            setValue={(code) => onEvent({ type: `codeUpdated`, code })}
          />
          <div className="flex justify-start flex-row-reverse mt-4">
            <Button
              type="button"
              onClick={() => onEvent({ type: `verifyCodeClicked` })}
              color="secondary"
              disabled={
                confirmationCode.match(/^\d{6}$/) === null ||
                confirmationRequest.state === `ongoing`
              }
              className="ml-3"
            >
              {confirmationRequest.state === `ongoing` ? `Verifying...` : `Verify code`}
            </Button>
            <Button
              type="button"
              onClick={() => onEvent({ type: `sendCodeClicked` })}
              color="tertiary"
              disabled={!methodValid(props) || confirmationRequest.state === `ongoing`}
            >
              Resend
            </Button>
          </div>
        </>
      )}
    </div>
    <Button
      type="button"
      onClick={() => onEvent({ type: `cancelClicked` })}
      color="tertiary"
      fullWidth
      className="mt-auto justify-end"
      size="large"
    >
      Cancel
    </Button>
  </div>
);

export default EditNotificationSidebar;

// helpers

function methodValid(props: CreatePendingNotificationMethod.Input): boolean {
  switch (props.case) {
    case `email`:
      return props.email?.match(/^.+@.+$/) !== null;
    case `text`:
      return (
        props.phoneNumber !== undefined &&
        props.phoneNumber.match(/\d{4}/) !== null &&
        props.phoneNumber.match(/^(\d|\(|\)| |-|\+)+$/) !== null
      );
    case `slack`:
      return (
        props.token?.startsWith(`xoxb-`) &&
        props.channelName?.length > 1 &&
        props.channelId?.length > 3
      );
  }
}
