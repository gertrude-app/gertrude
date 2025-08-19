import { MenuBar } from '@macos/appviews';
import cx from 'classnames';
import React from 'react';
import type { Meta, StoryFn } from '@storybook/react';

export default {
  title: 'MacOS App/MenuBar', // eslint-disable-line
  component: MenuBar,
  parameters: { layout: `centered` },
} satisfies Meta<typeof MenuBar>;

type MenuBarWrapperProps = {
  colors: string;
  theme: `light` | `dark`;
} & React.ComponentProps<typeof MenuBar>;

const LightTemplate: StoryFn<typeof MenuBar> = () => (
  <DifferentModesAcrossColors theme="light" />
);
export const LightMode = LightTemplate.bind({});

const DarkTemplate: StoryFn<typeof MenuBar> = () => (
  <DifferentModesAcrossColors theme="dark" />
);
export const DarkMode = DarkTemplate.bind({});

const NotConnectedTemplate: StoryFn<typeof MenuBar> = () => (
  <BothThemes case="notConnected" filterInstalled={false} {...commonProps} />
);
export const NotConnected = NotConnectedTemplate.bind({});

const NotConnectedActionsTemplate: StoryFn<typeof MenuBar> = () => (
  <BothThemes
    case="notConnected"
    filterInstalled={true}
    {...commonProps}
    showingNotConnectedActions
  />
);
export const NotConnectedActions = NotConnectedActionsTemplate.bind({});

const UpdateNagTemplate: StoryFn<typeof MenuBar> = () => (
  <BothThemes
    case="connected"
    {...commonProps}
    recordingKeystrokes
    recordingScreen
    filterState={{ case: `on` }}
    updateStatus="nag"
  />
);
export const UpdateNag = UpdateNagTemplate.bind({});

const UpdateRequiredTemplate: StoryFn<typeof MenuBar> = () => (
  <BothThemes
    case="connected"
    {...commonProps}
    recordingKeystrokes
    recordingScreen
    filterState={{ case: `on` }}
    updateStatus="require"
  />
);
export const UpdateRequired = UpdateRequiredTemplate.bind({});

const EnteringCodeTemplate: StoryFn<typeof MenuBar> = () => (
  <BothThemes case="enteringConnectionCode" {...commonProps} />
);
export const EnteringCode = EnteringCodeTemplate.bind({});

const EnteringCodeInvalidTemplate: StoryFn<typeof MenuBar> = () => (
  <BothThemes case="enteringConnectionCode" {...commonProps} connectionCode="invalid" />
);
export const EnteringCodeInvalid = EnteringCodeInvalidTemplate.bind({});

const ConnectingTemplate: StoryFn<typeof MenuBar> = () => (
  <BothThemes case="connecting" {...commonProps} />
);
export const Connecting = ConnectingTemplate.bind({});

const ConnectSuccessTemplate: StoryFn<typeof MenuBar> = () => (
  <BothThemes case="connectionSucceded" userName="Little Jimmy" {...commonProps} />
);
export const Connected = ConnectSuccessTemplate.bind({});

const ConnectFailedTemplate: StoryFn<typeof MenuBar> = () => (
  <BothThemes
    case="connectionFailed"
    error="Printer caught on fire, some really long error lets push it onto two lines"
    {...commonProps}
  />
);
export const ConnectFailed = ConnectFailedTemplate.bind({});

// helpers
const MenuBarWrapper: React.FC<MenuBarWrapperProps> = (props) => (
  <div className={cx(props.colors, `rounded-2xl shrink-0 overflow-hidden`, props.theme)}>
    <MenuBar {...props} />
  </div>
);

const BothThemes: React.FC<React.ComponentProps<typeof MenuBar>> = (props) => (
  <div className="flex flex-col space-y-4">
    <MenuBarWrapper
      {...props}
      theme="light"
      colors="bg-gradient-to-l from-[rgb(149,149,149)] to-[rgb(236,236,236)]"
    />
    <MenuBarWrapper
      {...props}
      theme="dark"
      colors="bg-gradient-to-l from-[rgb(34,34,34)] to-[rgb(126,126,126)]"
    />
  </div>
);

const DifferentModesAcrossColors: React.FC<{ theme: `light` | `dark` }> = ({ theme }) => {
  const propOptions: Record<
    `first` | `second` | `third` | `fourth` | `fifth` | `sixth`,
    React.ComponentProps<typeof MenuBarWrapper>
  > = {
    first: {
      colors: ``,
      theme,
      case: `connected`,
      recordingKeystrokes: true,
      recordingScreen: true,
      filterState: { case: `on` },
      ...commonProps,
    },
    second: {
      colors: ``,
      theme,
      case: `connected`,
      recordingKeystrokes: false,
      recordingScreen: true,
      filterState: { case: `off` },
      ...commonProps,
      adminAttentionRequired: true,
    },
    third: {
      colors: ``,
      theme,
      case: `connected`,
      recordingKeystrokes: false,
      recordingScreen: false,
      filterState: { case: `suspended`, resuming: `3 minutes from now` },
      ...commonProps,
    },
    fourth: {
      colors: ``,
      theme,
      case: `connected`,
      recordingKeystrokes: true,
      recordingScreen: true,
      filterState: { case: `downtime`, ending: `5 hours from now` },
      ...commonProps,
    },
    fifth: {
      colors: ``,
      theme,
      case: `connected`,
      recordingKeystrokes: true,
      recordingScreen: true,
      filterState: { case: `downtime`, ending: `5 hours from now` },
      ...commonProps,
      showingDowntimePauseDuration: true,
    },
    sixth: {
      colors: ``,
      theme,
      case: `connected`,
      recordingKeystrokes: true,
      recordingScreen: false,
      filterState: { case: `downtimePaused`, resuming: `3 minutes from now` },
      ...commonProps,
    },
  };
  return (
    <div className="flex flex-row space-x-4">
      <div className="flex flex-col space-y-4">
        <MenuBarWrapper
          {...propOptions.first}
          colors={theme === `light` ? `bg-[rgb(236,236,236)]` : `bg-[rgb(126,126,126)]`}
        />
        <MenuBarWrapper
          {...propOptions.second}
          colors={theme === `light` ? `bg-[rgb(236,236,236)]` : `bg-[rgb(126,126,126)]`}
        />
        <MenuBarWrapper
          {...propOptions.third}
          colors={theme === `light` ? `bg-[rgb(236,236,236)]` : `bg-[rgb(126,126,126)]`}
        />
        <MenuBarWrapper
          {...propOptions.fourth}
          colors={theme === `light` ? `bg-[rgb(236,236,236)]` : `bg-[rgb(126,126,126)]`}
        />
        <MenuBarWrapper
          {...propOptions.fifth}
          colors={theme === `light` ? `bg-[rgb(236,236,236)]` : `bg-[rgb(126,126,126)]`}
        />
        <MenuBarWrapper
          {...propOptions.sixth}
          colors={theme === `light` ? `bg-[rgb(236,236,236)]` : `bg-[rgb(126,126,126)]`}
        />
      </div>
      <div className="flex flex-col space-y-4">
        <MenuBarWrapper
          {...propOptions.first}
          colors={
            theme === `light`
              ? `bg-gradient-to-l from-[rgb(149,149,149)] to-[rgb(236,236,236)]`
              : `bg-gradient-to-l from-[rgb(34,34,34)] to-[rgb(126,126,126)]`
          }
        />
        <MenuBarWrapper
          {...propOptions.second}
          colors={
            theme === `light`
              ? `bg-gradient-to-l from-[rgb(149,149,149)] to-[rgb(236,236,236)]`
              : `bg-gradient-to-l from-[rgb(34,34,34)] to-[rgb(126,126,126)]`
          }
        />
        <MenuBarWrapper
          {...propOptions.third}
          colors={
            theme === `light`
              ? `bg-gradient-to-l from-[rgb(149,149,149)] to-[rgb(236,236,236)]`
              : `bg-gradient-to-l from-[rgb(34,34,34)] to-[rgb(126,126,126)]`
          }
        />
        <MenuBarWrapper
          {...propOptions.fourth}
          colors={
            theme === `light`
              ? `bg-gradient-to-l from-[rgb(149,149,149)] to-[rgb(236,236,236)]`
              : `bg-gradient-to-l from-[rgb(34,34,34)] to-[rgb(126,126,126)]`
          }
        />
        <MenuBarWrapper
          {...propOptions.fifth}
          colors={
            theme === `light`
              ? `bg-gradient-to-l from-[rgb(149,149,149)] to-[rgb(236,236,236)]`
              : `bg-gradient-to-l from-[rgb(34,34,34)] to-[rgb(126,126,126)]`
          }
        />
        <MenuBarWrapper
          {...propOptions.sixth}
          colors={
            theme === `light`
              ? `bg-gradient-to-l from-[rgb(149,149,149)] to-[rgb(236,236,236)]`
              : `bg-gradient-to-l from-[rgb(34,34,34)] to-[rgb(126,126,126)]`
          }
        />
      </div>
      <div className="flex flex-col space-y-4">
        <MenuBarWrapper
          {...propOptions.first}
          colors={theme === `light` ? `bg-[rgb(149,149,149)]` : `bg-[rgb(34,34,34)]`}
        />
        <MenuBarWrapper
          {...propOptions.second}
          colors={theme === `light` ? `bg-[rgb(149,149,149)]` : `bg-[rgb(34,34,34)]`}
        />
        <MenuBarWrapper
          {...propOptions.third}
          colors={theme === `light` ? `bg-[rgb(149,149,149)]` : `bg-[rgb(34,34,34)]`}
        />
        <MenuBarWrapper
          {...propOptions.fourth}
          colors={theme === `light` ? `bg-[rgb(149,149,149)]` : `bg-[rgb(34,34,34)]`}
        />
        <MenuBarWrapper
          {...propOptions.fifth}
          colors={theme === `light` ? `bg-[rgb(149,149,149)]` : `bg-[rgb(34,34,34)]`}
        />
        <MenuBarWrapper
          {...propOptions.sixth}
          colors={theme === `light` ? `bg-[rgb(149,149,149)]` : `bg-[rgb(34,34,34)]`}
        />
      </div>
    </div>
  );
};

const commonProps = {
  connectionCode: `123456`,
  adminAttentionRequired: false,
  showingNotConnectedActions: false,
  showingDowntimePauseDuration: false,
  emit: () => {},
  dispatch: () => {},
};
