export type SecurityEvent = {
  title: string;
  subtitle?: string;
  explanation: string;
  time: string; // '7:23 AM', etc.
  date: string; // 'May 12, 2026', etc.
  severity: `high` | `medium` | `low`;
} & (
  | {
      type: `mac-app`;
      personName: string;
      deviceName: string;
    }
  | {
      type: `admin-dashbaord`;
      ipAddress: string;
    }
);

export const mockSecurityEvents: SecurityEvent[] = [
  {
    type: `admin-dashbaord`,
    title: `Successful login`,
    subtitle: `Using email and password`,
    explanation: `This event occurs whenever a parent successfully logs into the parents admin website. Should be investigated if you do not recognize the successful login as your own.`,
    ipAddress: `127.0.0.1`,
    time: `9:52 AM`,
    date: `May 25, 2026`,
    severity: `low`,
  },
  {
    type: `admin-dashbaord`,
    title: `Successful login`,
    subtitle: `Using email and password`,
    explanation: `This event occurs whenever a parent successfully logs into the parents admin website. Should be investigated if you do not recognize the successful login as your own.`,
    ipAddress: `172.16.4.28`,
    time: `10:21 AM`,
    date: `May 18, 2026`,
    severity: `low`,
  },
  {
    type: `mac-app`,
    title: `Filter suspension expired`,
    explanation: `This event occurs when a filter suspension ends after the scheduled time. It does not represent a safety risk.`,
    personName: `Jimmy`,
    deviceName: `MacBook Air 13-inch, M2`,
    time: `7:31 AM`,
    date: `May 15, 2026`,
    severity: `low`,
  },
  {
    type: `admin-dashbaord`,
    title: `Successful login`,
    subtitle: `Using email and password`,
    explanation: `This event occurs whenever a parent successfully logs into the parents admin website. Should be investigated if you do not recognize the successful login as your own.`,
    ipAddress: `10.0.0.42`,
    time: `11:33 AM`,
    date: `May 15, 2026`,
    severity: `low`,
  },
  {
    type: `mac-app`,
    title: `Filter suspended remotely`,
    subtitle: `For 11 hrs`,
    explanation: `This event occurs when a parent account accepts a request to suspend the filter. As long as the parent accepted the request, this event is normal.`,
    personName: `Jimmy`,
    deviceName: `MacBook Air 13-inch, M2`,
    time: `8:30 PM`,
    date: `May 14, 2026`,
    severity: `medium`,
  },
  {
    type: `mac-app`,
    title: `Filter suspension granted by admin`,
    subtitle: `For 30 min`,
    explanation: `This event occurs when a filter suspension is granted from the computer by an admin-privileged user. If a parent did not authenticate, this represents the child suspending the filter themselves.`,
    personName: `Maggie`,
    deviceName: `Kitchen iMac`,
    time: `10:41 AM`,
    date: `May 12, 2026`,
    severity: `high`,
  },
  {
    type: `mac-app`,
    title: `Blocked app launch attempted`,
    subtitle: `App: Music`,
    explanation: `This event occurs when a child tries to launch an app designated blocked by the parent. There is no security risk as Gertrude will not allow the app to open, but repeated events do represent an attempt by the child to launch forbidden apps.`,
    personName: `Maggie`,
    deviceName: `Kitchen iMac`,
    time: `10:38 AM`,
    date: `May 12, 2026`,
    severity: `medium`,
  },
];
