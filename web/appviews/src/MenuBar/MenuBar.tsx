import cx from 'classnames';
import React from 'react';
import type { AppEvent, AppState, ViewAction, ViewState } from './menubar-store';
import type { PropsOf } from '../lib/store';
import { containerize } from '../lib/store';
import store from './menubar-store';
import ConnectFailed from './states/ConnectFailed';
import ConnectSucceeded from './states/ConnectSucceeded';
import EnteringConnectionCode from './states/EnteringConnectionCode';
import NotConnected from './states/NotConnected';
import NotConnectedActions from './states/NotConnectedActions';
import Throbbing from './states/Throbbing';
import UpdateNag from './states/UpdateNag';
import UpdateRequired from './states/UpdateRequired';
import Connected from './states/connected';

type Props = PropsOf<AppState, ViewState, AppEvent, ViewAction>;

export const MenuBar: React.FC<Props> = ({
  connectionCode,
  showingNotConnectedActions,
  emit,
  dispatch,
  ...props
}) => {
  if (props.case === `enteringConnectionCode`) {
    return (
      <EnteringConnectionCode
        emit={emit}
        dispatch={dispatch}
        connectionCode={connectionCode}
      />
    );
  }

  if (props.case === `connecting`) {
    return <Throbbing />;
  }

  if (props.case === `connectionFailed`) {
    return <ConnectFailed emit={emit} error={props.error} />;
  }

  if (props.case === `connectionSucceded`) {
    return <ConnectSucceeded emit={emit} userName={props.userName} />;
  }

  if (props.case === `connected` && props.updateStatus === `nag`) {
    return <UpdateNag emit={emit} />;
  }

  if (props.case === `connected` && props.updateStatus === `require`) {
    return <UpdateRequired emit={emit} />;
  }

  if (props.case === `connected`) {
    return (
      <Connected
        emit={emit}
        dispatch={dispatch}
        showingDowntimePauseDuration={props.showingDowntimePauseDuration}
        filterState={props.filterState}
        recordingScreen={props.recordingScreen}
        recordingKeystrokes={props.recordingKeystrokes}
        adminAttentionRequired={props.adminAttentionRequired}
      />
    );
  }

  if (props.case === `notConnected` && showingNotConnectedActions) {
    return (
      <NotConnectedActions
        emit={emit}
        onBackClicked={() => dispatch({ type: `toggleShowingNotConnectedActions` })}
        filterInstalled={props.filterInstalled}
      />
    );
  }

  return (
    <NotConnected
      emit={emit}
      onActionsIconClicked={() => dispatch({ type: `toggleShowingNotConnectedActions` })}
    />
  );
};

export default containerize<AppState, AppEvent, ViewState, ViewAction>(store, MenuBar);

export const MenuBarSized: React.FC<{
  children: React.ReactNode;
  className?: string;
}> = ({ children, className }) => (
  <div
    className={cx(
      `overflow-hidden relative`,
      `w-[400px] h-[300px]`,
      `os-gte-14:w-[428px] os-gte-14:h-[328px] os-gte-14:p-[14px]`,
      className,
    )}
  >
    {children}
  </div>
);
