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
          { value: `Email`, display: `Email` },
          { value: `Text`, display: `Text` },
          { value: `Slack`, display: `Slack` },
        ]}
        selectedOption={props.type}
        setSelected={(methodType) => onEvent({ type: `method_type_updated`, methodType })}
      />
      {props.type === `Email` ? (
        <TextInput
          key="email"
          type="email"
          value={props.value.email}
          setValue={(email) => onEvent({ type: `email_address_updated`, email })}
          label="Email address:"
          required
        />
      ) : props.type === `Text` ? (
        <TextInput
          key="text"
          label="Phone number:"
          type="text"
          required
          value={props.value.phoneNumber}
          setValue={(phoneNumber) =>
            onEvent({ type: `text_phone_number_updated`, phoneNumber })
          }
        />
      ) : (
        <>
          <TextInput
            key="text"
            label="Channel name:"
            type="text"
            required
            value={props.value.channelName}
            setValue={(channelName) =>
              onEvent({ type: `slack_channel_name_updated`, channelName })
            }
          />
          <TextInput
            label="Channel ID:"
            type="text"
            required
            value={props.value.channelId}
            setValue={(channelId) =>
              onEvent({ type: `slack_channel_id_updated`, channelId })
            }
          />
          <TextInput
            label="Bot token:"
            type="text"
            placeholder="xoxb-xxxxxxxxxx-xxxxxxxxxx-xxxxxxxxxx-xxxxxxxxxx"
            required
            value={props.value.token}
            setValue={(token) => onEvent({ type: `slack_token_updated`, token })}
          />
        </>
      )}
    </div>
    <div className="flex flex-col mt-3">
      {sendCodeRequest.state !== `succeeded` ? (
        <Button
          type="button"
          onClick={() => onEvent({ type: `send_code_clicked` })}
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
            setValue={(code) => onEvent({ type: `code_updated`, code })}
          />
          <div className="flex justify-start flex-row-reverse mt-4">
            <Button
              type="button"
              onClick={() => onEvent({ type: `verify_code_clicked` })}
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
              onClick={() => onEvent({ type: `send_code_clicked` })}
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
      onClick={() => onEvent({ type: `cancel_clicked` })}
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
  switch (props.type) {
    case `Email`:
      return props.value.email?.match(/^.+@.+$/) !== null;
    case `Text`:
      return (
        props.value.phoneNumber !== undefined &&
        props.value.phoneNumber.match(/\d{4}/) !== null &&
        props.value.phoneNumber.match(/^(\d|\(|\)| |-|\+)+$/) !== null
      );
    case `Slack`:
      return (
        props.value.token?.startsWith(`xoxb-`) &&
        props.value.channelName?.length > 1 &&
        props.value.channelId?.length > 3
      );
  }
}
