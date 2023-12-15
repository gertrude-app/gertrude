import React, { useState } from 'react';
import StepSwitcher, {
  OnboardingPage,
} from '@macos/appviews/src/Onboarding/StepSwitcher';
import * as Step from '@macos/appviews/src/Onboarding/Steps';
import type { OnboardingStep } from '@macos/appviews/src/Onboarding/onboarding-store';

const OnboardingStatefulSwitcher: React.FC = () => {
  const [step, setStep] = useState<OnboardingStep>(`welcome`);
  const [connectChildState, setConnectChildState] = useState<
    'idle' | 'ongoing' | 'failed' | 'succeeded'
  >(`idle`);

  return (
    <div
      onClick={() => {
        switch (step) {
          case `welcome`:
            setTimeout(() => setStep(`confirmGertrudeAccount`), 1000); // this is handled in the component, but need to simulate it here
            break;
          case `wrongInstallDir`:
            setStep(`confirmGertrudeAccount`);
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
            setStep(`exemptUsers`);
            break;
          case `exemptUsers`:
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
      <StepSwitcher ready>
        <OnboardingPage step="welcome" component={<Step.Welcome />} />
        <OnboardingPage
          step="wrongInstallDir"
          component={<Step.AppNotInApplicationsDir />}
        />
        <OnboardingPage
          step="confirmGertrudeAccount"
          component={<Step.ConfirmGertrudeAccount />}
        />
        <OnboardingPage step="noGertrudeAccount" component={<Step.NoGertrudeAccount />} />
        <OnboardingPage
          step="macosUserAccountType"
          component={
            <Step.MacosUserAccountType
              current={{ id: 502, name: `Suzy`, isAdmin: false }}
              users={[
                { id: 501, name: `Bob McParent`, isAdmin: true },
                { id: 502, name: `Suzy`, isAdmin: false },
              ]}
            />
          }
          confetti
        />
        <OnboardingPage
          step="getChildConnectionCode"
          component={<Step.GetConnectionCode />}
        />
        <OnboardingPage
          step="connectChild"
          component={
            <Step.ConnectChild
              connectionCode={`123456`}
              request={{ case: connectChildState, payload: `Suzy` }}
            />
          }
          confetti={connectChildState === `succeeded`}
          confettiDeps={[connectChildState]}
        />
        <OnboardingPage
          step="allowNotifications_start"
          component={<Step.AllowNotifications step="allowNotifications_start" />}
        />
        <OnboardingPage
          step="allowNotifications_grant"
          component={<Step.AllowNotifications step="allowNotifications_grant" />}
        />
        <OnboardingPage
          step="allowNotifications_failed"
          component={<Step.AllowNotifications step="allowNotifications_failed" />}
        />
        <OnboardingPage
          step="allowScreenshots_required"
          component={<Step.AllowScreenshots step="allowScreenshots_required" />}
        />
        <OnboardingPage
          step="allowScreenshots_grantAndRestart"
          component={<Step.AllowScreenshots step="allowScreenshots_grantAndRestart" />}
        />
        <OnboardingPage
          step="allowScreenshots_success"
          component={<Step.AllowScreenshots step="allowScreenshots_success" />}
          confetti
        />
        <OnboardingPage
          step="allowScreenshots_failed"
          component={<Step.AllowScreenshots step="allowScreenshots_failed" />}
        />
        <OnboardingPage
          step="allowKeylogging_required"
          component={<Step.AllowKeylogging step="allowKeylogging_required" />}
        />
        <OnboardingPage
          step="allowKeylogging_grant"
          component={<Step.AllowKeylogging step="allowKeylogging_grant" />}
        />
        <OnboardingPage
          step="allowKeylogging_failed"
          component={<Step.AllowKeylogging step="allowKeylogging_failed" />}
        />
        <OnboardingPage
          step="installSysExt_explain"
          component={<Step.InstallSysExt step="installSysExt_explain" />}
        />
        <OnboardingPage
          step="installSysExt_allow"
          component={<Step.InstallSysExt step="installSysExt_allow" />}
        />
        <OnboardingPage
          step="installSysExt_failed"
          component={<Step.InstallSysExt step="installSysExt_failed" />}
        />
        <OnboardingPage
          step="installSysExt_success"
          component={<Step.InstallSysExt step="installSysExt_success" />}
          confetti
        />
        <OnboardingPage
          step="exemptUsers"
          component={<Step.ExemptUsers exemptUserIds={[]} exemptableUserIds={[501]} />}
        />
        <OnboardingPage step="locateMenuBarIcon" component={<Step.LocateMenuBarIcon />} />
        <OnboardingPage step="viewHealthCheck" component={<Step.ViewHealthCheck />} />
        <OnboardingPage step="howToUseGertrude" component={<Step.HowToUseGertrude />} />
        <OnboardingPage step="finish" component={<Step.Finish />} />
      </StepSwitcher>
    </div>
  );
};

export default OnboardingStatefulSwitcher;
