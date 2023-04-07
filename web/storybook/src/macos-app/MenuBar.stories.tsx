import React from 'react';
import cx from 'classnames';
import { MenuBar } from '@macos/appviews';
import type { StoryFn, ComponentMeta } from '@storybook/react';

export default {
  title: 'MacOS App/MenuBar', // eslint-disable-line
  component: MenuBar,
  parameters: {
    layout: `centered`,
  },
} as ComponentMeta<typeof MenuBar>;

type MenuBarWrapperProps = {
  colors: string;
  theme: 'light' | 'dark';
} & React.ComponentProps<typeof MenuBar>;

const LightTemplate: StoryFn<typeof MenuBar> = () => (
  <ThreeModesThreeColors theme="light" />
);
export const LightMode = LightTemplate.bind({});

const DarkTemplate: StoryFn<typeof MenuBar> = () => (
  <ThreeModesThreeColors theme="dark" />
);
export const DarkMode = DarkTemplate.bind({});

const NotConnectedTemplate: StoryFn<typeof MenuBar> = () => (
  <BothThemes case="notConnected" {...commonProps} />
);
export const NotConnected = NotConnectedTemplate.bind({});

const EnteringCodeTemplate: StoryFn<typeof MenuBar> = () => (
  <BothThemes case="enteringConnectionCode" {...commonProps} />
);
export const EnteringCode = EnteringCodeTemplate.bind({});

const ConnectingTemplate: StoryFn<typeof MenuBar> = () => (
  <BothThemes case="connecting" {...commonProps} />
);
export const Connecting = ConnectingTemplate.bind({});

const ConnectFailedTemplate: StoryFn<typeof MenuBar> = () => (
  <BothThemes case="connectionFailed" error="Printer caught on fire" {...commonProps} />
);
export const ConnectFailed = ConnectFailedTemplate.bind({});

// helpers
const MenuBarWrapper: React.FC<MenuBarWrapperProps> = (props) => {
  return (
    <div className={cx(props.colors, `rounded-2xl shrink-0`, props.theme)}>
      <MenuBar {...props} />
    </div>
  );
};

const BothThemes: React.FC<React.ComponentProps<typeof MenuBar>> = (props) => {
  return (
    <div className="flex flex-col space-y-4">
      <MenuBarWrapper
        {...props}
        theme="light"
        colors="bg-gradient-to-l from-[rgb(140,140,140)] to-[rgb(230,230,236)]"
      />
      <MenuBarWrapper
        {...props}
        theme="dark"
        colors="bg-gradient-to-l from-[rgb(27,27,27)] to-[rgb(120,120,120)]"
      />
    </div>
  );
};

const ThreeModesThreeColors: React.FC<{ theme: 'light' | 'dark' }> = ({ theme }) => {
  const propOptions: Record<
    'first' | 'second' | 'third',
    React.ComponentProps<typeof MenuBarWrapper>
  > = {
    first: {
      colors: '',
      theme,
      case: `connected`,
      recordingKeystrokes: true,
      recordingScreen: true,
      filterState: { case: `on` },
      ...commonProps,
    },
    second: {
      colors: '',
      theme,
      case: `connected`,
      recordingKeystrokes: false,
      recordingScreen: true,
      filterState: { case: `off` },
      ...commonProps,
    },
    third: {
      colors: '',
      theme,
      case: `connected`,
      recordingKeystrokes: false,
      recordingScreen: false,
      filterState: { case: `suspended`, expiration: `3 minutes from now` },
      ...commonProps,
    },
  };
  return (
    <div className="flex flex-row space-x-4">
      <div className="flex flex-col space-y-4">
        <MenuBarWrapper
          {...propOptions.first}
          colors={theme === 'light' ? 'bg-[rgb(230,230,236)]' : 'bg-[rgb(120,120,120)]'}
        />
        <MenuBarWrapper
          {...propOptions.second}
          colors={theme === 'light' ? 'bg-[rgb(230,230,236)]' : 'bg-[rgb(120,120,120)]'}
        />
        <MenuBarWrapper
          {...propOptions.third}
          colors={theme === 'light' ? 'bg-[rgb(230,230,236)]' : 'bg-[rgb(120,120,120)]'}
        />
      </div>
      <div className="flex flex-col space-y-4">
        <MenuBarWrapper
          {...propOptions.first}
          colors={
            theme === 'light'
              ? 'bg-gradient-to-l from-[rgb(140,140,140)] to-[rgb(230,230,236)]'
              : 'bg-gradient-to-l from-[rgb(27,27,27)] to-[rgb(120,120,120)]'
          }
        />
        <MenuBarWrapper
          {...propOptions.second}
          colors={
            theme === 'light'
              ? 'bg-gradient-to-l from-[rgb(140,140,140)] to-[rgb(230,230,236)]'
              : 'bg-gradient-to-l from-[rgb(27,27,27)] to-[rgb(120,120,120)]'
          }
        />
        <MenuBarWrapper
          {...propOptions.third}
          colors={
            theme === 'light'
              ? 'bg-gradient-to-l from-[rgb(140,140,140)] to-[rgb(230,230,236)]'
              : 'bg-gradient-to-l from-[rgb(27,27,27)] to-[rgb(120,120,120)]'
          }
        />
      </div>
      <div className="flex flex-col space-y-4">
        <MenuBarWrapper
          {...propOptions.first}
          colors={theme === 'light' ? 'bg-[rgb(140,140,140)]' : 'bg-[rgb(27,27,27)]'}
        />
        <MenuBarWrapper
          {...propOptions.second}
          colors={theme === 'light' ? 'bg-[rgb(140,140,140)]' : 'bg-[rgb(27,27,27)]'}
        />
        <MenuBarWrapper
          {...propOptions.third}
          colors={theme === 'light' ? 'bg-[rgb(140,140,140)]' : 'bg-[rgb(27,27,27)]'}
        />
      </div>
    </div>
  );
};

const commonProps = {
  connectionCode: `123456`,
  emit: () => {},
  dispatch: () => {},
};
