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

const ThreeModes: React.FC<{ colors: string }> = ({ colors }) => (
  <div className="flex flex-col space-y-4">
    <div className={cx(colors, `rounded-2xl`)}>
      <MenuBar
        case="connected"
        recordingKeystrokes={true}
        recordingScreen={true}
        filterState={{ case: `on` }}
        {...props}
      />
    </div>
    <div className={cx(colors, `rounded-2xl`)}>
      <MenuBar
        case="connected"
        recordingKeystrokes={false}
        recordingScreen={true}
        filterState={{ case: `off` }}
        {...props}
      />
    </div>
    <div className={cx(colors, `rounded-2xl`)}>
      <MenuBar
        case="connected"
        recordingKeystrokes={false}
        recordingScreen={false}
        filterState={{ case: `suspended`, expiration: `3 minutes from now` }}
        {...props}
      />
    </div>
  </div>
);

const LightTemplate: StoryFn<typeof MenuBar> = () => (
  <ThreeModes colors="bg-gradient-to-l from-[rgb(140,140,140)] to-[rgb(230,230,236)]" />
);
export const LightMode = LightTemplate.bind({});

const LightOverLightTemplate: StoryFn<typeof MenuBar> = () => (
  <ThreeModes colors="bg-[rgb(230,230,236)]" />
);
export const LightModeOverLightBackground = LightOverLightTemplate.bind({});

const LightOverDarkTemplate: StoryFn<typeof MenuBar> = () => (
  <ThreeModes colors="bg-[rgb(140,140,140)]" />
);
export const LightModeOverDarkBackground = LightOverDarkTemplate.bind({});

const DarkTemplate: StoryFn<typeof MenuBar> = () => (
  <ThreeModes colors="dark bg-gradient-to-l from-[rgb(27,27,27)] to-[rgb(120,120,120)]" />
);
export const DarkMode = DarkTemplate.bind({});

const DarkOverLightTemplate: StoryFn<typeof MenuBar> = () => (
  <ThreeModes colors="dark bg-[rgb(120,120,120)]" />
);
export const DarkModeOverLightBackground = DarkOverLightTemplate.bind({});

const DarkOverDarkTemplate: StoryFn<typeof MenuBar> = () => (
  <ThreeModes colors="dark bg-[rgb(27,27,27)]" />
);
export const DarkModeOverDarkBackground = DarkOverDarkTemplate.bind({});

const NotConnectedTemplate: StoryFn<typeof MenuBar> = () => {
  return (
    <div className="flex flex-col space-y-4">
      <div
        className={cx(
          `bg-gradient-to-l from-[rgb(140,140,140)] to-[rgb(230,230,236)]`,
          `rounded-2xl`,
        )}
      >
        <MenuBar case="notConnected" {...props} />
      </div>
      <div
        className={cx(
          `dark bg-gradient-to-l from-[rgb(27,27,27)] to-[rgb(120,120,120)]`,
          `rounded-2xl`,
        )}
      >
        <MenuBar case="notConnected" {...props} />
      </div>
    </div>
  );
};
export const NotConnected = NotConnectedTemplate.bind({});

const EnteringCodeTemplate: StoryFn<typeof MenuBar> = () => {
  return (
    <div className="flex flex-col space-y-4">
      <div
        className={cx(
          `bg-gradient-to-l from-[rgb(140,140,140)] to-[rgb(230,230,236)]`,
          `rounded-2xl`,
        )}
      >
        <MenuBar case="enteringConnectionCode" {...props} />
      </div>
      <div
        className={cx(
          `dark bg-gradient-to-l from-[rgb(27,27,27)] to-[rgb(120,120,120)]`,
          `rounded-2xl`,
        )}
      >
        <MenuBar case="enteringConnectionCode" {...props} connectionCode="not valid" />
      </div>
    </div>
  );
};
export const EnteringCode = EnteringCodeTemplate.bind({});

const ConnectingTemplate: StoryFn<typeof MenuBar> = () => {
  return (
    <div className="flex flex-col space-y-4">
      <div
        className={cx(
          `bg-gradient-to-l from-[rgb(140,140,140)] to-[rgb(230,230,236)]`,
          `rounded-2xl`,
        )}
      >
        <MenuBar case="connecting" {...props} />
      </div>
      <div
        className={cx(
          `dark bg-gradient-to-l from-[rgb(27,27,27)] to-[rgb(120,120,120)]`,
          `rounded-2xl`,
        )}
      >
        <MenuBar case="connecting" {...props} />
      </div>
    </div>
  );
};
export const Connecting = ConnectingTemplate.bind({});

const ConnectFailedTemplate: StoryFn<typeof MenuBar> = () => {
  return (
    <div className="flex flex-col space-y-4">
      <div
        className={cx(
          `bg-gradient-to-l from-[rgb(140,140,140)] to-[rgb(230,230,236)]`,
          `rounded-2xl`,
        )}
      >
        <MenuBar case="connectionFailed" error="Printer caught on fire" {...props} />
      </div>
      <div
        className={cx(
          `dark bg-gradient-to-l from-[rgb(27,27,27)] to-[rgb(120,120,120)]`,
          `rounded-2xl`,
        )}
      >
        <MenuBar case="connectionFailed" error="Printer caught on fire" {...props} />
      </div>
    </div>
  );
};
export const ConnectFailed = ConnectFailedTemplate.bind({});

const props = {
  connectionCode: `123456`,
  emit: () => {},
  dispatch: () => {},
};
