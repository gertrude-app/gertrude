import React from 'react';
import type { AppState, ViewState, AppEvent, ViewAction } from './onboarding-store';
import type { PropsOf } from '../lib/store';
import { containerize } from '../lib/store';
import store from './onboarding-store';
import * as Step from './Steps';

type Props = PropsOf<AppState, ViewState, AppEvent, ViewAction>;

export const Onboarding: React.FC<Props> = ({
  emit,
  dispatch,
  connectionCode,
  step,
  connectChildRequest,
  macOSUser,
  os,
}) => {
  let stepComponent: React.ReactNode;
  switch (step) {
    case `welcome`:
      stepComponent = <Step.Welcome emit={emit} />;
      break;
    case `confirmGertrudeAccount`:
      stepComponent = <Step.ConfirmGertrudeAccount emit={emit} />;
      break;
    case `noGertrudeAccount`:
      stepComponent = <Step.NoGertrudeAccount emit={emit} />;
      break;
    case `macosUserAccountType`:
      stepComponent = (
        <Step.MacosUserAccountType
          current={macOSUser.current}
          users={macOSUser.list}
          remediationStep={macOSUser.remediationStep}
          emit={emit}
        />
      );
      break;
    case `getChildConnectionCode`:
      stepComponent = <Step.GetConnectionCode emit={emit} />;
      break;
    case `connectChild`:
      stepComponent = (
        <Step.ConnectChild
          connectionCode={connectionCode}
          request={connectChildRequest}
          dispatch={dispatch}
          emit={emit}
        />
      );
      break;
    case `allowNotifications_start`:
    case `allowNotifications_grant`:
      stepComponent = <Step.AllowNotifications os={os} step={step} emit={emit} />;
      break;
    case `allowScreenshots_required`:
    case `allowScreenshots_openSysSettings`:
    case `allowScreenshots_grantAndRestart`:
    case `allowScreenshots_success`:
      stepComponent = <Step.AllowScreenshots os={os} step={step} emit={emit} />;
      break;
    case `allowKeylogging_required`:
    case `allowKeylogging_openSysSettings`:
    case `allowKeylogging_grant`:
    case `allowKeylogging_failed`:
    case `allowKeylogging_success`:
      stepComponent = <Step.AllowKeylogging os={os} step={step} emit={emit} />;
      break;
    case `installSysExt_explain`:
    case `installSysExt_start`:
    case `installSysExt_allowInstall`:
    case `installSysExt_allowFiltering`:
    case `installSysExt_failed`:
    case `installSysExt_success`:
      stepComponent = <Step.InstallSysExt os={os} step={step} emit={emit} />;
      break;
    case `locateMenuBarIcon`:
      stepComponent = <Step.LocateMenuBarIcon emit={emit} />;
      break;
    case `viewHealthCheck`:
      stepComponent = <Step.ViewHealthCheck emit={emit} />;
      break;
    case `howToUseGertrude`:
      stepComponent = <Step.HowToUseGertrude emit={emit} />;
      break;
    case `finish`:
      stepComponent = <Step.Finish emit={emit} />;
      break;
  }
  return (
    <div className="h-screen">
      {/* <div className="absolute top-0 right-0 bottom-0 p-3">Parent Setup</div> */}
      {stepComponent}
    </div>
  );
};

export default containerize<AppState, AppEvent, ViewState, ViewAction>(store, Onboarding);
