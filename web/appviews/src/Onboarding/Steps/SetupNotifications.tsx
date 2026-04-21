import { CodeInput, TextInput } from '@shared/components';
import { parseE164, prettyE164 } from '@shared/phone-numbers';
import cx from 'classnames';
import React, { useContext, useEffect, useState } from 'react';
import type { RequestState } from '../onboarding-store';
import OnboardingContext, { WithinActiveStepContext } from '../OnboardingContext';
import * as Onboarding from '../UtilityComponents';

interface SendCodePayload {
  methodId: UUID;
  phoneNumber: string;
}

const PHONE_PLACEHOLDERS = [`(555) 555-5555`, `+44 7700 900123`, `+33 6 12 34 56 78`];

const Header: React.FC = () => (
  <div className="w-14 h-14 bg-violet-100 rounded-2xl flex items-center justify-center mb-5">
    <i className="fa-solid fa-mobile-screen-button text-2xl text-violet-500" />
  </div>
);

interface EnterPhoneProps {
  request: RequestState<SendCodePayload>;
}

export const SetupNotificationsEnterPhone: React.FC<EnterPhoneProps> = ({ request }) => {
  const { emit, currentStep, osVersion } = useContext(OnboardingContext);
  const withinActiveStep = useContext(WithinActiveStepContext);
  const shouldAutoFocus =
    currentStep === `setupNotifications_enterPhone` && osVersion.major > 12;

  const [phoneNumber, setPhoneNumber] = useState(``);
  const [placeholderIdx, setPlaceholderIdx] = useState(0);

  useEffect(() => {
    const id = setInterval(() => {
      setPlaceholderIdx((i) => (i + 1) % PHONE_PLACEHOLDERS.length);
    }, 4000);
    return () => clearInterval(id);
  }, []);

  const ongoing = request.case === `ongoing`;
  const normalizedPhone = parseE164(phoneNumber);
  const phoneValid = normalizedPhone !== null;
  const error = request.case === `failed` ? request.error : undefined;

  function emitSend(): void {
    if (!normalizedPhone || ongoing) return;
    emit({ case: `sendOnboardingNotificationCode`, phoneNumber: normalizedPhone });
  }

  return (
    <Onboarding.Centered>
      <Header />
      <Onboarding.Heading centered>Get notified on your phone</Onboarding.Heading>
      <Onboarding.Text centered className="mt-3 mb-8 max-w-xl">
        Add your phone number so Gertrude can text you when your child needs something
        unblocked, or asks to suspend the filter.
      </Onboarding.Text>
      <form
        noValidate
        className="flex w-[540px] items-start gap-3"
        onSubmit={(e) => {
          e.preventDefault();
          emitSend();
        }}
      >
        <TextInput
          type="text"
          value={phoneNumber}
          setValue={setPhoneNumber}
          placeholder={PHONE_PLACEHOLDERS[placeholderIdx]}
          disabled={!withinActiveStep || ongoing}
          autoFocus={shouldAutoFocus}
          autoComplete="tel"
          className="flex-grow"
        />
        <GradientSubmitButton
          disabled={!phoneValid || ongoing}
          ongoing={ongoing}
          icon="fa-solid fa-paper-plane"
        />
      </form>
      <div className="w-[540px] h-6 mt-2 px-1">
        {error && (
          <p className="text-sm text-red-500 antialiased">
            <i className="fa-solid fa-circle-exclamation mr-1.5" />
            {error}
          </p>
        )}
      </div>
      <Onboarding.SecondaryButton className="mt-8">
        Set up later
      </Onboarding.SecondaryButton>
    </Onboarding.Centered>
  );
};

interface VerifyCodeProps {
  sendRequest: RequestState<SendCodePayload>;
  confirmRequest: RequestState;
}

export const SetupNotificationsVerifyCode: React.FC<VerifyCodeProps> = ({
  sendRequest,
  confirmRequest,
}) => {
  const { emit, currentStep, osVersion } = useContext(OnboardingContext);
  const withinActiveStep = useContext(WithinActiveStepContext);
  const shouldAutoFocus =
    currentStep === `setupNotifications_verifyCode` && osVersion.major > 12;

  const [code, setCode] = useState(``);

  if (sendRequest.case !== `succeeded`) return null;

  const ongoing = confirmRequest.case === `ongoing`;
  const codeValid = code.match(/^\d{6}$/) !== null;
  const error = confirmRequest.case === `failed` ? confirmRequest.error : undefined;

  function emitConfirm(): void {
    if (sendRequest.case !== `succeeded` || !codeValid || ongoing) return;
    emit({
      case: `confirmOnboardingNotificationCode`,
      methodId: sendRequest.payload.methodId,
      code: Number(code),
    });
  }

  return (
    <Onboarding.Centered>
      <Header />
      <Onboarding.Heading centered>Enter the code we just sent</Onboarding.Heading>
      <Onboarding.Text centered className="mt-3 mb-2 max-w-xl">
        We sent a 6-digit code to{` `}
        <span className="font-semibold text-slate-700">
          {prettyE164(sendRequest.payload.phoneNumber)}
        </span>
        .
      </Onboarding.Text>
      <button
        type="button"
        onClick={() => emit({ case: `changeOnboardingPhoneNumberClicked` })}
        className="text-sm text-violet-500 hover:text-violet-600 hover:underline mb-6 antialiased"
        tabIndex={-1}
      >
        <i className="fa-solid fa-arrow-left mr-1.5" />
        Use a different number
      </button>
      <CodeInput
        value={code}
        onChange={setCode}
        onSubmit={emitConfirm}
        disabled={!withinActiveStep || ongoing}
        autoFocus={shouldAutoFocus}
        className="w-64 mb-8"
      />
      <SaveButton
        onClick={emitConfirm}
        canSubmit={codeValid && !ongoing}
        ongoing={ongoing}
        label="Save and continue"
      />
      <ErrorLine error={error} />
      <Onboarding.EscapeHatchButton>Set up later</Onboarding.EscapeHatchButton>
    </Onboarding.Centered>
  );
};

export const SetupNotificationsSuccess: React.FC = () => (
  <Onboarding.Centered>
    <Header />
    <Onboarding.Heading centered>Notifications are on</Onboarding.Heading>
    <Onboarding.Text centered className="mt-3 mb-8 max-w-xl">
      You can change these any time from the parents website.
    </Onboarding.Text>
    <Onboarding.PrimaryButton icon="fa-solid fa-arrow-right">
      Continue
    </Onboarding.PrimaryButton>
  </Onboarding.Centered>
);

const SaveButton: React.FC<{
  onClick(): void;
  canSubmit: boolean;
  ongoing: boolean;
  label: string;
}> = ({ onClick, canSubmit, ongoing, label }) => (
  <button
    type="button"
    onClick={onClick}
    disabled={!canSubmit}
    tabIndex={-1}
    className={cx(
      `px-8 h-[50px] rounded-2xl text-lg font-medium flex justify-center items-center gap-3 transition-[transform,box-shadow,background-color,opacity] duration-200 min-w-[240px]`,
      canSubmit
        ? `bg-gradient-to-r from-violet-500 to-fuchsia-500 text-white shadow-lg shadow-violet-500/40 hover:scale-[102%] active:scale-[98%] hover:shadow-xl hover:shadow-violet-500/50`
        : `bg-slate-100 text-slate-300 cursor-not-allowed`,
    )}
  >
    {ongoing ? (
      <i className="fa-solid fa-spinner animate-spin" />
    ) : (
      <>
        <span>{label}</span>
        <i className="fa-solid fa-arrow-right" />
      </>
    )}
  </button>
);

const GradientSubmitButton: React.FC<{
  disabled: boolean;
  ongoing: boolean;
  icon: string;
}> = ({ disabled, ongoing, icon }) => (
  <button
    type="submit"
    disabled={disabled}
    tabIndex={-1}
    className={cx(
      `shrink-0 w-14 h-[50px] rounded-xl flex justify-center items-center transition-[transform,box-shadow,background-color,color] duration-200`,
      !disabled
        ? `bg-gradient-to-br from-violet-500 to-fuchsia-500 text-white shadow-lg shadow-violet-500/40 hover:scale-[103%] active:scale-[97%] hover:shadow-xl hover:shadow-violet-500/50`
        : `bg-slate-100 text-slate-300 cursor-not-allowed`,
    )}
  >
    {ongoing ? (
      <i className="fa-solid fa-spinner animate-spin text-lg" />
    ) : (
      <i className={cx(icon, `text-lg`)} />
    )}
  </button>
);

const ErrorLine: React.FC<{ error?: string }> = ({ error }) => (
  <div className="w-[540px] h-6 mt-3 px-1 text-center">
    {error && (
      <p className="text-sm text-red-500 antialiased">
        <i className="fa-solid fa-circle-exclamation mr-1.5" />
        {error}
      </p>
    )}
  </div>
);
