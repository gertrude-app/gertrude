import React from 'react';
import cx from 'classnames';
import type { AppState, ViewState, AppEvent, ViewAction } from './menubar-store';
import type { PropsOf } from '../lib/store';
import { containerize } from '../lib/store';
import store from './menubar-store';
import EnteringConnectionCode from './states/EnteringConnectionCode';
import ConnectFailed from './states/ConnectFailed';
import Throbbing from './states/Throbbing';
import NotConnected from './states/NotConnected';
import ConnectSucceeded from './states/ConnectSucceeded';
import UpdateNag from './states/UpdateNag';
import UpdateRequired from './states/UpdateRequired';
import NotConnectedActions from './states/NotConnectedActions';
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

// not sure why i have to specify the generics here... 🤔
export default containerize<AppState, AppEvent, ViewState, ViewAction>(store, MenuBar);

export const MenuBarSized: React.FC<{
  children: React.ReactNode;
  className?: string;
}> = ({ children, className }) => (
  <div className={cx(`w-[400px] h-[300px] overflow-hidden relative`, className)}>
    {children}
  </div>
);
