import React from 'react';
import cx from 'classnames';
import type { AppState, ViewState, AppEvent, ViewAction } from './menubar-store';
import type { PropsOf } from '../lib/store';
import { containerize } from '../lib/store';
import store from './menubar-store';
import Connected from './states/Connected';
import EnteringConnectionCode from './states/EnteringConnectionCode';
import ConnectFailed from './states/ConnectFailed';
import Connecting from './states/Connecting';
import Welcome from './states/Welcome';

type Props = PropsOf<AppState, ViewState, AppEvent, ViewAction>;

export const MenuBar: React.FC<Props> = ({
  connectionCode,
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
    return <Connecting />;
  }

  if (props.case === `connectionFailed`) {
    return <ConnectFailed error={props.error} />;
  }

  if (props.case === `connectionSucceded`) {
    return (
      <MenuBarSized>
        connected to user: {props.userName}
        {` `}
        <button onClick={() => emit({ case: `welcomeAdminClicked` })}>go to admin</button>
      </MenuBarSized>
    );
  }

  if (props.case === `connected`) {
    return (
      <Connected
        emit={emit}
        filterState={props.filterState}
        recordingScreen={props.recordingScreen}
        recordingKeystrokes={props.recordingKeystrokes}
      />
    );
  }
  return <Welcome emit={emit} />;
};

// not sure why i have to specify the generics here... 🤔
export default containerize<AppState, AppEvent, ViewState, ViewAction>(store, MenuBar);

export const MenuBarSized: React.FC<{
  children: React.ReactNode;
  className?: string;
}> = ({ children, className }) => (
  <div className={cx(`w-[400px] h-[300px]`, className)}>{children}</div>
);
