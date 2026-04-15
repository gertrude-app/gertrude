import { parseE164 } from '@dash/utils';
import { Button, SelectMenu, TextInput } from '@shared/components';
import React, { useState } from 'react';
import type {
  CreatePendingNotificationMethod,
  NewAdminNotificationMethodEvent as Event,
  PendingNotificationMethod,
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
}) => {
  const isNtfy = props.case === `ntfy`;
  const ntfyCreated = isNtfy && sendCodeRequest.state === `succeeded`;
  return (
    <div className="p-8 flex flex-col grow h-full items-stretch">
      <h2 className="text-2xl font-extrabold text-slate-700 mb-8">
        New notification method
      </h2>
      <div className="flex flex-col space-y-6">
        <SelectMenu
          label="Method:"
          options={[
            { value: `email`, display: `Email` },
            { value: `text`, display: `Text` },
            { value: `slack`, display: `Slack` },
            { value: `ntfy`, display: `ntfy` },
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
        ) : props.case === `slack` ? (
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
        ) : !ntfyCreated ? (
          <NtfyIntro />
        ) : null}
      </div>
      <div className="flex flex-col mt-3">
        {!ntfyCreated && sendCodeRequest.state !== `succeeded` ? (
          <Button
            type="button"
            onClick={() => onEvent({ type: `sendCodeClicked` })}
            color="secondary"
            disabled={!methodValid(props) || sendCodeRequest.state === `ongoing`}
            className="self-end mt-4"
          >
            {sendCodeRequest.state === `ongoing`
              ? isNtfy
                ? `Creating...`
                : `Sending...`
              : isNtfy
                ? `Create ntfy topic`
                : `Send verification code`}
          </Button>
        ) : isNtfy && props.case === `ntfy` ? (
          <NtfySuccess
            topic={props.topic}
            onDone={() => onEvent({ type: `verifyCodeClicked` })}
          />
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
        className="mt-auto"
        size="medium"
      >
        Cancel
      </Button>
    </div>
  );
};

export default EditNotificationSidebar;

// helpers

const IOS_APP_URL = `https://apps.apple.com/us/app/ntfy/id1625396347`;
const ANDROID_APP_URL = `https://play.google.com/store/apps/details?id=io.heckel.ntfy`;

type Platform = `ios` | `android` | `unknown`;

function detectPlatform(): Platform {
  if (typeof navigator === `undefined`) return `unknown`;
  const ua = navigator.userAgent;
  if (/Android/i.test(ua)) return `android`;
  if (/iPhone|iPad|iPod/i.test(ua)) return `ios`;
  return `unknown`;
}

const NtfyIntro: React.FC = () => {
  const platform = detectPlatform();
  return (
    <div className="text-sm text-slate-600 bg-slate-50 rounded-lg p-4 leading-relaxed">
      <p className="mb-3">
        <a
          href="https://ntfy.sh"
          target="_blank"
          rel="noreferrer"
          className="text-violet-700 underline"
        >
          ntfy
        </a>
        {` `}
        is a free push notification service. Install the ntfy app, then click{` `}
        <b>Create ntfy topic</b> below. We'll generate a unique topic just for your
        Gertrude notifications — you'll subscribe to it in the ntfy app.
      </p>
      <div className="flex flex-col gap-2">
        {(platform === `ios` || platform === `unknown`) && (
          <a
            href={IOS_APP_URL}
            target="_blank"
            rel="noreferrer"
            className="inline-flex items-center justify-center gap-2 bg-white hover:bg-slate-100 border border-slate-200 text-slate-600 rounded-lg px-3 py-2 text-xs font-medium"
          >
            <i className="fa-brands fa-apple text-base" />
            Download for iOS
          </a>
        )}
        {(platform === `android` || platform === `unknown`) && (
          <a
            href={ANDROID_APP_URL}
            target="_blank"
            rel="noreferrer"
            className="inline-flex items-center justify-center gap-2 bg-white hover:bg-slate-100 border border-slate-200 text-slate-600 rounded-lg px-3 py-2 text-xs font-medium"
          >
            <i className="fa-brands fa-android text-base" />
            Download for Android
          </a>
        )}
      </div>
    </div>
  );
};

const NtfySuccess: React.FC<{ topic: string; onDone(): unknown }> = ({
  topic,
  onDone,
}) => {
  const [copied, setCopied] = useState(false);
  const androidDeepLink = `ntfy://ntfy.sh/${topic}`;
  const webUrl = `https://ntfy.sh/${topic}`;
  const platform = detectPlatform();
  const copy = (): void => {
    navigator.clipboard.writeText(topic).then(() => {
      setCopied(true);
      setTimeout(() => setCopied(false), 2000);
    });
  };
  return (
    <div className="mt-6 flex flex-col space-y-4">
      <div className="bg-violet-50 rounded-lg p-4">
        <p className="text-sm text-slate-700 leading-relaxed mb-3">
          Subscribe to this topic in the ntfy app to start receiving notifications:
        </p>
        <div className="flex items-center gap-2 bg-white rounded border border-slate-200 p-3">
          <code className="flex-grow text-md text-slate-800 font-mono break-all select-all">
            {topic}
          </code>
          <Button
            type="button"
            onClick={copy}
            color="tertiary"
            size="small"
            className="shrink-0"
          >
            <i className={`fa fa-${copied ? `check` : `clone`}`} />
          </Button>
        </div>
        {platform === `android` && (
          <a href={androidDeepLink} className="block mt-3">
            <Button type="button" color="secondary" fullWidth onClick={() => {}}>
              <i className="fa-brands fa-android mr-2" />
              Open in ntfy app
            </Button>
          </a>
        )}
      </div>
      <p className="text-xs text-slate-500 leading-relaxed">
        Open the ntfy app, tap <b>+</b>, and paste the topic above. A test notification
        was sent — you'll see it once subscribed. You can also view the topic in a browser
        at{` `}
        <a
          href={webUrl}
          target="_blank"
          rel="noreferrer"
          className="text-violet-700 underline break-all"
        >
          ntfy.sh/{topic}
        </a>
        .
      </p>
      <div className="flex justify-end">
        <Button type="button" onClick={onDone} color="secondary">
          Done
        </Button>
      </div>
    </div>
  );
};

function methodValid(props: CreatePendingNotificationMethod.Input): boolean {
  switch (props.case) {
    case `email`:
      return props.email?.match(/^.+@.+$/) !== null;
    case `text`:
      return parseE164(props.phoneNumber) !== null;
    case `slack`:
      return (
        props.token?.startsWith(`xoxb-`) &&
        props.channelName?.length > 1 &&
        props.channelId?.length > 3
      );
    case `ntfy`:
      return true;
  }
}
