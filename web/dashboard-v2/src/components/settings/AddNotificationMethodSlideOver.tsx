import { Banner, Button, Input, Select, SlideOver, toast } from '@gertrude/ui';
import {
  BellDotIcon,
  CheckIcon,
  CopyIcon,
  ExternalLinkIcon,
  type LucideIcon,
  MailIcon,
  MessageCircleIcon,
  SendIcon,
} from 'lucide-react';
import React from 'react';
import type { NotificationMethod } from '#/lib/mock';

type NotificationMethodType = NotificationMethod[`type`];
type FlowState = `compose` | `codeSent` | `ntfyCreated`;
type Platform = `ios` | `android` | `unknown`;

type MethodSelectOption = {
  value: NotificationMethodType;
  label: string;
  description: string;
  icon: LucideIcon | React.ReactNode;
};

type Props = {
  open: boolean;
  onOpenChange: (open: boolean) => void;
};

const methodOptions = [
  {
    value: `email`,
    label: `Email`,
    description: `Receive Gertrude notifications in your inbox.`,
    icon: MailIcon,
  },
  {
    value: `text`,
    label: `Text`,
    description: `Receive Gertrude notifications by text message.`,
    icon: MessageCircleIcon,
  },
  {
    value: `slack`,
    label: `Slack`,
    description: `Send Gertrude notifications to a Slack channel.`,
    icon: <img src="/slack-logo.png" alt="" className="h-3.5 w-3.5 shrink-0" />,
  },
  {
    value: `ntfy`,
    label: `ntfy`,
    description: `Receive Gertrude notifications through a private ntfy topic.`,
    icon: (
      <img src="/ntfy-logo.svg" alt="" className="h-3.5 w-3.5 shrink-0 rounded-[3px]" />
    ),
  },
  {
    value: `push`,
    label: `Push`,
    description: `Receive Gertrude notifications on this browser or device.`,
    icon: BellDotIcon,
  },
] satisfies MethodSelectOption[];

const IOS_APP_URL = `https://apps.apple.com/us/app/ntfy/id1625396347`;
const ANDROID_APP_URL = `https://play.google.com/store/apps/details?id=io.heckel.ntfy`;

const sleep = (ms: number): Promise<void> =>
  new Promise((resolve) => window.setTimeout(resolve, ms));

const AddNotificationMethodSlideOver: React.FC<Props> = ({ open, onOpenChange }) => {
  const [methodType, setMethodType] = React.useState<NotificationMethodType>(`email`);
  const [flowState, setFlowState] = React.useState<FlowState>(`compose`);
  const [emailAddress, setEmailAddress] = React.useState(``);
  const [phoneNumber, setPhoneNumber] = React.useState(``);
  const [slackChannelName, setSlackChannelName] = React.useState(``);
  const [slackChannelId, setSlackChannelId] = React.useState(``);
  const [slackBotToken, setSlackBotToken] = React.useState(``);
  const [confirmationCode, setConfirmationCode] = React.useState(``);
  const [ntfyTopic, setNtfyTopic] = React.useState(`gertrude-family-alerts-8k4tq9`);
  const [submitting, setSubmitting] = React.useState(false);
  const needsCode = [`email`, `text`, `slack`].includes(methodType);
  const primaryButtonLabel = getPrimaryButtonLabel(methodType, flowState);
  const primaryButtonDisabled = getPrimaryButtonDisabled({
    methodType,
    flowState,
    emailAddress,
    phoneNumber,
    slackChannelName,
    slackChannelId,
    slackBotToken,
    confirmationCode,
  });

  const reset = (): void => {
    setMethodType(`email`);
    setFlowState(`compose`);
    setEmailAddress(``);
    setPhoneNumber(``);
    setSlackChannelName(``);
    setSlackChannelId(``);
    setSlackBotToken(``);
    setConfirmationCode(``);
    setNtfyTopic(`gertrude-family-alerts-8k4tq9`);
    setSubmitting(false);
  };

  const handleOpenChange = (nextOpen: boolean): void => {
    if (!nextOpen) {
      reset();
    }

    onOpenChange(nextOpen);
  };

  const selectMethodType = (nextMethodType: NotificationMethodType): void => {
    setMethodType(nextMethodType);
    setFlowState(`compose`);
    setConfirmationCode(``);
  };

  const finishWithToast = (success: string): void => {
    setSubmitting(true);
    void sleep(900)
      .then(() => {
        toast.success(success);
        handleOpenChange(false);
      })
      .finally(() => setSubmitting(false));
  };

  const handlePrimaryAction = (): void => {
    if (primaryButtonDisabled || submitting) {
      return;
    }

    if (flowState === `ntfyCreated`) {
      handleOpenChange(false);
      return;
    }

    if (methodType === `ntfy`) {
      setNtfyTopic(`gertrude-family-alerts-8k4tq9`);
      setFlowState(`ntfyCreated`);
      return;
    }

    if (methodType === `push`) {
      finishWithToast(`Push notifications enabled.`);
      return;
    }

    if (flowState === `codeSent`) {
      finishWithToast(`Notification method verified.`);
      return;
    }

    setFlowState(`codeSent`);
  };

  return (
    <SlideOver
      open={open}
      onOpenChange={handleOpenChange}
      ariaLabel="Add notification method"
      heading="Add notification method"
      subheading="Choose where Gertrude should send request and security alerts."
      size="medium"
      withPx
    >
      <div className="flex h-full flex-col">
        <div className="min-h-0 flex-1 overflow-y-auto pb-6">
          <div className="flex max-w-xl flex-col gap-5">
            <Select
              label="Method"
              selected={methodType}
              setSelected={selectMethodType}
              possibleValues={methodOptions}
            />
            {flowState === `ntfyCreated` ? (
              <NtfySuccess topic={ntfyTopic} />
            ) : flowState === `codeSent` && needsCode ? (
              <VerificationCodeForm
                methodType={methodType}
                confirmationCode={confirmationCode}
                setConfirmationCode={setConfirmationCode}
              />
            ) : (
              <MethodFields
                methodType={methodType}
                emailAddress={emailAddress}
                setEmailAddress={setEmailAddress}
                phoneNumber={phoneNumber}
                setPhoneNumber={setPhoneNumber}
                slackChannelName={slackChannelName}
                setSlackChannelName={setSlackChannelName}
                slackChannelId={slackChannelId}
                setSlackChannelId={setSlackChannelId}
                slackBotToken={slackBotToken}
                setSlackBotToken={setSlackBotToken}
              />
            )}
          </div>
        </div>
        <div className="-mx-4 flex shrink-0 items-center justify-between gap-3 border-t border-stone-200 bg-stone-50/95 px-4 py-3 @lg/slide:-mx-6 @lg/slide:px-6 @lg/slide:py-4">
          <Button type="button" variant="ghost" onClick={() => handleOpenChange(false)}>
            Cancel
          </Button>
          <div className="flex items-center gap-2">
            {flowState === `codeSent` && (
              <Button
                type="button"
                variant="default"
                onClick={() => setConfirmationCode(``)}
              >
                Resend
              </Button>
            )}
            <Button
              type="button"
              variant="primary"
              disabled={primaryButtonDisabled || submitting}
              loading={submitting}
              onClick={handlePrimaryAction}
              icon={flowState === `compose` ? SendIcon : undefined}
            >
              {primaryButtonLabel}
            </Button>
          </div>
        </div>
      </div>
    </SlideOver>
  );
};

export default AddNotificationMethodSlideOver;

const MethodFields: React.FC<{
  methodType: NotificationMethodType;
  emailAddress: string;
  setEmailAddress: (value: string) => void;
  phoneNumber: string;
  setPhoneNumber: (value: string) => void;
  slackChannelName: string;
  setSlackChannelName: (value: string) => void;
  slackChannelId: string;
  setSlackChannelId: (value: string) => void;
  slackBotToken: string;
  setSlackBotToken: (value: string) => void;
}> = ({
  methodType,
  emailAddress,
  setEmailAddress,
  phoneNumber,
  setPhoneNumber,
  slackChannelName,
  setSlackChannelName,
  slackChannelId,
  setSlackChannelId,
  slackBotToken,
  setSlackBotToken,
}) => {
  switch (methodType) {
    case `email`:
      return (
        <Input
          type="email"
          value={emailAddress}
          setValue={setEmailAddress}
          label="Email address"
          placeholder="parent@example.com"
          autoComplete="email"
          required
          helperText="Gertrude will send a six-digit verification code before this address can receive notifications."
        />
      );
    case `text`:
      return (
        <Input
          type="text"
          value={phoneNumber}
          setValue={setPhoneNumber}
          label="Phone number"
          placeholder="+1 555 555 0142"
          autoComplete="tel"
          required
          helperText="Use an E.164 number so messages can be delivered reliably."
        />
      );
    case `slack`:
      return (
        <div className="flex flex-col gap-4">
          <Input
            type="text"
            value={slackChannelName}
            setValue={setSlackChannelName}
            label="Channel name"
            placeholder="#gertrude-alerts"
            required
          />
          <Input
            type="text"
            value={slackChannelId}
            setValue={setSlackChannelId}
            label="Channel ID"
            placeholder="C08GERTRUDE"
            required
            helperText="Slack channel IDs usually start with C."
          />
          <Input
            type="text"
            value={slackBotToken}
            setValue={setSlackBotToken}
            label="Bot token"
            placeholder="xoxb-xxxxxxxxxx-xxxxxxxxxx-xxxxxxxxxx-xxxxxxxxxx"
            required
          />
        </div>
      );
    case `ntfy`:
      return <NtfyIntro />;
    case `push`:
      return <PushIntro />;
  }
};

const VerificationCodeForm: React.FC<{
  methodType: NotificationMethodType;
  confirmationCode: string;
  setConfirmationCode: (value: string) => void;
}> = ({ methodType, confirmationCode, setConfirmationCode }) => (
  <div className="flex flex-col gap-4">
    <Banner>
      We sent a six-digit code to your {verificationDestination(methodType)}. Enter it
      here to finish adding this method.
    </Banner>
    <Input
      type="text"
      value={confirmationCode}
      setValue={setConfirmationCode}
      label="Verification code"
      placeholder="123456"
      autoComplete="one-time-code"
      required
    />
  </div>
);

const NtfyIntro: React.FC = () => {
  const platform = detectPlatform();

  return (
    <div className="flex flex-col gap-3 text-sm leading-6 text-stone-600">
      <p>
        <a
          href="https://ntfy.sh"
          target="_blank"
          rel="noreferrer"
          className="font-medium text-violet-700 underline decoration-violet-300 underline-offset-2"
        >
          ntfy
        </a>
        {` `}
        is a free push notification service. Install the app, then create a private topic
        for Gertrude notifications.
      </p>
      <div className="flex flex-col gap-2 @md/slide:flex-row">
        {(platform === `ios` || platform === `unknown`) && (
          <Button
            type="link"
            href={IOS_APP_URL}
            variant="default"
            className="justify-center"
            icon={ExternalLinkIcon}
          >
            Download for iOS
          </Button>
        )}
        {(platform === `android` || platform === `unknown`) && (
          <Button
            type="link"
            href={ANDROID_APP_URL}
            variant="default"
            className="justify-center"
            icon={ExternalLinkIcon}
          >
            Download for Android
          </Button>
        )}
      </div>
    </div>
  );
};

const NtfySuccess: React.FC<{ topic: string }> = ({ topic }) => {
  const [copied, setCopied] = React.useState(false);
  const webUrl = `https://ntfy.sh/${topic}`;
  const copyTopic = (): void => {
    if (!navigator.clipboard) {
      return;
    }

    void navigator.clipboard.writeText(topic).then(() => {
      setCopied(true);
      window.setTimeout(() => setCopied(false), 2000);
    });
  };

  return (
    <div className="flex flex-col gap-4">
      <Banner>
        <div className="flex flex-col gap-3">
          <p>Subscribe to this topic in the ntfy app to start receiving notifications.</p>
          <div className="flex items-center gap-2 rounded-lg border border-stone-300/80 bg-white p-2 shadow-sm shadow-stone-300/30">
            <code className="min-w-0 flex-grow break-all font-mono text-sm text-stone-800 select-all">
              {topic}
            </code>
            <Button
              type="button"
              variant="ghost"
              ariaLabel="Copy ntfy topic"
              onClick={copyTopic}
              icon={copied ? CheckIcon : CopyIcon}
            />
          </div>
        </div>
      </Banner>
      <p className="text-sm leading-6 text-stone-500">
        You can also view the topic in a browser at{` `}
        <a
          href={webUrl}
          target="_blank"
          rel="noreferrer"
          className="font-medium text-violet-700 underline decoration-violet-300 underline-offset-2"
        >
          ntfy.sh/{topic}
        </a>
        .
      </p>
    </div>
  );
};

const PushIntro: React.FC = () => (
  <div className="text-sm leading-6 text-stone-600">
    <p>
      Push notifications send Gertrude alerts directly to this browser or device. The
      browser will ask for permission when you enable this method.
    </p>
    <p className="mt-3 text-xs leading-5 text-stone-500">
      If you use multiple browsers or devices, add each one separately.
    </p>
  </div>
);

function detectPlatform(): Platform {
  if (typeof navigator === `undefined`) {
    return `unknown`;
  }

  const ua = navigator.userAgent;

  if (/Android/i.test(ua)) {
    return `android`;
  }

  if (/iPhone|iPad|iPod/i.test(ua)) {
    return `ios`;
  }

  return `unknown`;
}

function verificationDestination(methodType: NotificationMethodType): string {
  switch (methodType) {
    case `email`:
      return `email address`;
    case `text`:
      return `phone number`;
    case `slack`:
      return `Slack channel`;
    case `ntfy`:
      return `ntfy topic`;
    case `push`:
      return `device`;
  }
}

function getPrimaryButtonLabel(
  methodType: NotificationMethodType,
  flowState: FlowState,
): string {
  if (flowState === `ntfyCreated`) {
    return `Done`;
  }

  if (flowState === `codeSent`) {
    return `Verify code`;
  }

  switch (methodType) {
    case `ntfy`:
      return `Create ntfy topic`;
    case `push`:
      return `Enable push notifications`;
    default:
      return `Send verification code`;
  }
}

function getPrimaryButtonDisabled(input: {
  methodType: NotificationMethodType;
  flowState: FlowState;
  emailAddress: string;
  phoneNumber: string;
  slackChannelName: string;
  slackChannelId: string;
  slackBotToken: string;
  confirmationCode: string;
}): boolean {
  if (input.flowState === `codeSent`) {
    return input.confirmationCode.match(/^\d{6}$/) === null;
  }

  if (input.flowState !== `compose`) {
    return false;
  }

  switch (input.methodType) {
    case `email`:
      return input.emailAddress.match(/^.+@.+\..+$/) === null;
    case `text`:
      return input.phoneNumber.match(/^\+?[0-9 ().-]{7,}$/) === null;
    case `slack`:
      return !(
        input.slackBotToken.startsWith(`xoxb-`) &&
        input.slackChannelName.length > 1 &&
        input.slackChannelId.length > 3
      );
    case `ntfy`:
    case `push`:
      return false;
  }
}
