import React from 'react';
import StepSwitcher, {
  OnboardingPage,
} from '@macos/appviews/src/Onboarding/StepSwitcher';
import * as Step from '@macos/appviews/src/Onboarding/Steps';
import type { OnboardingStep } from '@macos/appviews/src/Onboarding/onboarding-store';

const OnboardingStatefulSwitcher: React.FC = () => {
  const [step, setStep] = React.useState<OnboardingStep>(`welcome`);
  const [connectChildState, setConnectChildState] = React.useState<
    'idle' | 'ongoing' | 'failed' | 'succeeded'
  >(`idle`);

  return (
    <div
      onClick={() => {
        switch (step) {
          case `welcome`:
            setTimeout(() => setStep(`confirmGertrudeAccount`), 1000); // this is handled in the component, but need to simulate it here
            break;
          case `confirmGertrudeAccount`:
            setStep(`noGertrudeAccount`);
            break;
          case `noGertrudeAccount`:
            setStep(`macosUserAccountType`);
            break;
          case `macosUserAccountType`:
            setStep(`getChildConnectionCode`);
            break;
          case `getChildConnectionCode`:
            setStep(`connectChild`);
            break;
          case `connectChild`:
            if (connectChildState === `idle`) setConnectChildState(`ongoing`);
            if (connectChildState === `ongoing`) setConnectChildState(`succeeded`);
            else if (connectChildState === `succeeded`) setConnectChildState(`failed`);
            else if (connectChildState === `failed`) setStep(`allowNotifications_start`);
            break;
          case `allowNotifications_start`:
            setStep(`allowNotifications_grant`);
            break;
          case `allowNotifications_grant`:
            setStep(`allowNotifications_failed`);
            break;
          case `allowNotifications_failed`:
            setStep(`allowScreenshots_required`);
            break;
          case `allowScreenshots_required`:
            setStep(`allowScreenshots_openSysSettings`);
            break;
          case `allowScreenshots_openSysSettings`:
            setStep(`allowScreenshots_grantAndRestart`);
            break;
          case `allowScreenshots_grantAndRestart`:
            setStep(`allowScreenshots_success`);
            break;
          case `allowScreenshots_success`:
            setStep(`allowScreenshots_failed`);
            break;
          case `allowScreenshots_failed`:
            setStep(`allowKeylogging_required`);
            break;
          case `allowKeylogging_required`:
            setStep(`allowKeylogging_openSysSettings`);
            break;
          case `allowKeylogging_openSysSettings`:
            setStep(`allowKeylogging_grant`);
            break;
          case `allowKeylogging_grant`:
            setStep(`allowKeylogging_failed`);
            break;
          case `allowKeylogging_failed`:
            setStep(`installSysExt_explain`);
            break;
          case `installSysExt_explain`:
            setStep(`installSysExt_allow`);
            break;
          case `installSysExt_allow`:
            setStep(`installSysExt_failed`);
            break;
          case `installSysExt_failed`:
            setStep(`installSysExt_success`);
            break;
          case `installSysExt_success`:
            setStep(`locateMenuBarIcon`);
            break;
          case `locateMenuBarIcon`:
            setStep(`viewHealthCheck`);
            break;
          case `viewHealthCheck`:
            setStep(`howToUseGertrude`);
            break;
          case `howToUseGertrude`:
            setStep(`finish`);
            break;
          case `finish`:
            setStep(`welcome`);
            break;
        }
      }}
    >
      <StepSwitcher step={step}>
        <OnboardingPage step="welcome" component={<Step.Welcome emit={() => {}} />} />
        <OnboardingPage
          step="confirmGertrudeAccount"
          component={<Step.ConfirmGertrudeAccount emit={() => {}} />}
        />
        <OnboardingPage
          step="noGertrudeAccount"
          component={<Step.NoGertrudeAccount emit={() => {}} />}
        />
        <OnboardingPage
          step="macosUserAccountType"
          component={
            <Step.MacosUserAccountType
              current={{ id: 502, name: `Suzy`, isAdmin: false }}
              users={[
                { id: 501, name: `Bob McParent`, isAdmin: true },
                { id: 502, name: `Suzy`, isAdmin: false },
              ]}
              emit={() => {}}
            />
          }
          confetti
        />
        <OnboardingPage
          step="getChildConnectionCode"
          component={<Step.GetConnectionCode emit={() => {}} os="venturaOrLater" />}
        />
        <OnboardingPage
          step="connectChild"
          component={
            <Step.ConnectChild
              connectionCode={`123456`}
              request={{ state: connectChildState, payload: `Suzy` }}
              dispatch={() => {}}
              emit={() => {}}
            />
          }
          confetti={connectChildState === `succeeded`}
          confettiDeps={[connectChildState]}
        />
        <OnboardingPage
          step="allowNotifications_start"
          component={
            <Step.AllowNotifications
              os={`venturaOrLater`}
              step="allowNotifications_start"
              emit={() => {}}
            />
          }
        />
        <OnboardingPage
          step="allowNotifications_grant"
          component={
            <Step.AllowNotifications
              os={`venturaOrLater`}
              step="allowNotifications_grant"
              emit={() => {}}
            />
          }
        />
        <OnboardingPage
          step="allowNotifications_failed"
          component={
            <Step.AllowNotifications
              os={`venturaOrLater`}
              step="allowNotifications_failed"
              emit={() => {}}
            />
          }
        />
        <OnboardingPage
          step="allowScreenshots_required"
          component={
            <Step.AllowScreenshots
              os={`venturaOrLater`}
              step="allowScreenshots_required"
              emit={() => {}}
            />
          }
        />
        <OnboardingPage
          step="allowScreenshots_openSysSettings"
          component={
            <Step.AllowScreenshots
              os={`venturaOrLater`}
              step="allowScreenshots_openSysSettings"
              emit={() => {}}
            />
          }
        />
        <OnboardingPage
          step="allowScreenshots_grantAndRestart"
          component={
            <Step.AllowScreenshots
              os={`venturaOrLater`}
              step="allowScreenshots_grantAndRestart"
              emit={() => {}}
            />
          }
        />
        <OnboardingPage
          step="allowScreenshots_success"
          component={
            <Step.AllowScreenshots
              os={`venturaOrLater`}
              step="allowScreenshots_success"
              emit={() => {}}
            />
          }
          confetti
        />
        <OnboardingPage
          step="allowScreenshots_failed"
          component={
            <Step.AllowScreenshots
              os={`venturaOrLater`}
              step="allowScreenshots_failed"
              emit={() => {}}
            />
          }
        />
        <OnboardingPage
          step="allowKeylogging_required"
          component={
            <Step.AllowKeylogging
              os={`venturaOrLater`}
              step="allowKeylogging_required"
              emit={() => {}}
            />
          }
        />
        <OnboardingPage
          step="allowKeylogging_openSysSettings"
          component={
            <Step.AllowKeylogging
              os={`venturaOrLater`}
              step="allowKeylogging_openSysSettings"
              emit={() => {}}
            />
          }
        />
        <OnboardingPage
          step="allowKeylogging_grant"
          component={
            <Step.AllowKeylogging
              os={`venturaOrLater`}
              step="allowKeylogging_grant"
              emit={() => {}}
            />
          }
        />
        <OnboardingPage
          step="allowKeylogging_failed"
          component={
            <Step.AllowKeylogging
              os={`venturaOrLater`}
              step="allowKeylogging_failed"
              emit={() => {}}
            />
          }
        />
        <OnboardingPage
          step="installSysExt_explain"
          component={
            <Step.InstallSysExt
              os={`venturaOrLater`}
              step="installSysExt_explain"
              emit={() => {}}
            />
          }
        />
        <OnboardingPage
          step="installSysExt_allow"
          component={
            <Step.InstallSysExt
              os={`venturaOrLater`}
              step="installSysExt_allow"
              emit={() => {}}
            />
          }
        />
        <OnboardingPage
          step="installSysExt_failed"
          component={
            <Step.InstallSysExt
              os={`venturaOrLater`}
              step="installSysExt_failed"
              emit={() => {}}
            />
          }
        />
        <OnboardingPage
          step="installSysExt_success"
          component={
            <Step.InstallSysExt
              os={`venturaOrLater`}
              step="installSysExt_success"
              emit={() => {}}
            />
          }
          confetti
        />
        <OnboardingPage
          step="locateMenuBarIcon"
          component={<Step.LocateMenuBarIcon emit={() => {}} os="venturaOrLater" />}
        />
        <OnboardingPage
          step="viewHealthCheck"
          component={<Step.ViewHealthCheck emit={() => {}} os="venturaOrLater" />}
        />
        <OnboardingPage
          step="howToUseGertrude"
          component={<Step.HowToUseGertrude emit={() => {}} />}
        />
        <OnboardingPage step="finish" component={<Step.Finish emit={() => {}} />} />
      </StepSwitcher>
    </div>
  );
};

export default OnboardingStatefulSwitcher;
