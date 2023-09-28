import React from 'react';
import type { AppState, ViewState, AppEvent, ViewAction } from './onboarding-store';
import type { PropsOf } from '../lib/store';
import { containerize } from '../lib/store';
import store from './onboarding-store';
import * as Step from './Steps';
import StepSwitcher, { OnboardingPage } from './StepSwitcher';

type Props = PropsOf<AppState, ViewState, AppEvent, ViewAction>;

export const Onboarding: React.FC<Props> = ({
  emit,
  dispatch,
  connectionCode,
  step,
  connectChildRequest,
  macOSUser,
  os,
}) => (
  <StepSwitcher step={step}>
    <OnboardingPage step="welcome" component={<Step.Welcome emit={emit} />} />
    <OnboardingPage
      step="confirmGertrudeAccount"
      component={<Step.ConfirmGertrudeAccount emit={emit} />}
    />
    <OnboardingPage
      step="noGertrudeAccount"
      component={<Step.NoGertrudeAccount emit={emit} />}
    />
    <OnboardingPage
      step="macosUserAccountType"
      component={
        <Step.MacosUserAccountType
          current={macOSUser.current}
          users={macOSUser.list}
          remediationStep={macOSUser.remediationStep}
          emit={emit}
        />
      }
      confetti={!macOSUser.current.isAdmin}
    />
    <OnboardingPage
      step="getChildConnectionCode"
      component={<Step.GetConnectionCode emit={emit} os={os} />}
    />
    <OnboardingPage
      step="connectChild"
      component={
        <Step.ConnectChild
          connectionCode={connectionCode}
          request={connectChildRequest}
          dispatch={dispatch}
          emit={emit}
        />
      }
      confetti={connectChildRequest.state === `succeeded`}
      confettiDeps={[connectChildRequest.state]}
    />
    <OnboardingPage
      step="allowNotifications_start"
      component={
        <Step.AllowNotifications os={os} step="allowNotifications_start" emit={emit} />
      }
    />
    <OnboardingPage
      step="allowNotifications_grant"
      component={
        <Step.AllowNotifications os={os} step="allowNotifications_grant" emit={emit} />
      }
    />
    <OnboardingPage
      step="allowNotifications_failed"
      component={
        <Step.AllowNotifications os={os} step="allowNotifications_failed" emit={emit} />
      }
    />
    <OnboardingPage
      step="allowScreenshots_required"
      component={
        <Step.AllowScreenshots os={os} step="allowScreenshots_required" emit={emit} />
      }
    />
    <OnboardingPage
      step="allowScreenshots_openSysSettings"
      component={
        <Step.AllowScreenshots
          os={os}
          step="allowScreenshots_openSysSettings"
          emit={emit}
        />
      }
    />
    <OnboardingPage
      step="allowScreenshots_grantAndRestart"
      component={
        <Step.AllowScreenshots
          os={os}
          step="allowScreenshots_grantAndRestart"
          emit={emit}
        />
      }
    />
    <OnboardingPage
      step="allowScreenshots_success"
      component={
        <Step.AllowScreenshots os={os} step="allowScreenshots_success" emit={emit} />
      }
      confetti
    />
    <OnboardingPage
      step="allowScreenshots_failed"
      component={
        <Step.AllowScreenshots os={os} step="allowScreenshots_failed" emit={emit} />
      }
    />
    <OnboardingPage
      step="allowKeylogging_required"
      component={
        <Step.AllowKeylogging os={os} step="allowKeylogging_required" emit={emit} />
      }
    />
    <OnboardingPage
      step="allowKeylogging_openSysSettings"
      component={
        <Step.AllowKeylogging
          os={os}
          step="allowKeylogging_openSysSettings"
          emit={emit}
        />
      }
    />
    <OnboardingPage
      step="allowKeylogging_grant"
      component={
        <Step.AllowKeylogging os={os} step="allowKeylogging_grant" emit={emit} />
      }
    />
    <OnboardingPage
      step="allowKeylogging_failed"
      component={
        <Step.AllowKeylogging os={os} step="allowKeylogging_failed" emit={emit} />
      }
    />
    <OnboardingPage
      step="installSysExt_explain"
      component={<Step.InstallSysExt os={os} step="installSysExt_explain" emit={emit} />}
    />
    <OnboardingPage
      step="installSysExt_start"
      component={<Step.InstallSysExt os={os} step="installSysExt_start" emit={emit} />}
    />
    <OnboardingPage
      step="installSysExt_allowInstall"
      component={
        <Step.InstallSysExt os={os} step="installSysExt_allowInstall" emit={emit} />
      }
    />
    <OnboardingPage
      step="installSysExt_failed"
      component={<Step.InstallSysExt os={os} step="installSysExt_failed" emit={emit} />}
    />
    <OnboardingPage
      step="installSysExt_success"
      component={<Step.InstallSysExt os={os} step="installSysExt_success" emit={emit} />}
      confetti
    />
    <OnboardingPage
      step="locateMenuBarIcon"
      component={<Step.LocateMenuBarIcon emit={emit} os={os} />}
    />
    <OnboardingPage
      step="viewHealthCheck"
      component={<Step.ViewHealthCheck emit={emit} os={os} />}
    />
    <OnboardingPage
      step="howToUseGertrude"
      component={<Step.HowToUseGertrude emit={emit} />}
    />
    <OnboardingPage
      step="finish"
      component={<Step.Finish emit={emit} shown={step === `finish`} />}
    />
  </StepSwitcher>
);

export default containerize<AppState, AppEvent, ViewState, ViewAction>(store, Onboarding);
