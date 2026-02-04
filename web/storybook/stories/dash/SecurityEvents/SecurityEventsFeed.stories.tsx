import { SecurityEventsFeed } from '@dash/components';
import type { Meta, StoryObj } from '@storybook/react';
import { withStatefulChrome } from '../../decorators/StatefulChrome';
import { props, time } from '../../story-helpers';

const meta = {
  title: 'Dashboard/SecurityEvents/SecurityEventsFeed', // eslint-disable-line
  component: SecurityEventsFeed,
  parameters: { layout: `fullscreen` },
  decorators: [withStatefulChrome],
} satisfies Meta<typeof SecurityEventsFeed>;

type Story = StoryObj<typeof meta>;

const now = new Date(time.stable()).getTime();

export const Default: Story = props({
  events: [
    {
      case: `admin` as const,
      id: `1`,
      event: `Successful login`,
      detail: `using email/password`,
      explanation: `This event occurs whenever a parent successfully logs into the parents admin website. Should be investigated if you do not recognize the successful login as your own.`,
      severity: `all` as const,
      ipAddress: `107.205.36.96`,
      createdAt: new Date(now - 1000 * 60 * 30).toISOString(),
    },
    {
      case: `admin` as const,
      id: `2`,
      event: `Blocked apps changed`,
      detail: `child: Gabriel`,
      explanation: `This event occurs when a parent changes which apps are blocked for a child. Should be investigated if the change was not made by you.`,
      severity: `recommended` as const,
      ipAddress: `107.205.36.96`,
      createdAt: new Date(now - 1000 * 60 * 45).toISOString(),
    },
    {
      case: `child` as const,
      id: `3`,
      childId: `child-1`,
      childName: `Gabriel`,
      deviceId: `device-1`,
      deviceName: `Mac Mini`,
      event: `App launched`,
      explanation: `This event occurs when the Gertrude app is launched. Only investigate it if seems to be occuring more than expected.`,
      severity: `all` as const,
      createdAt: new Date(now - 1000 * 60 * 60 * 2).toISOString(),
    },
    {
      case: `child` as const,
      id: `4`,
      childId: `child-1`,
      childName: `Gabriel`,
      deviceId: `device-1`,
      deviceName: `Mac Mini`,
      event: `Filter suspension granted by admin`,
      detail: `for 9 hrs`,
      explanation: `This event occurs when a filter suspension is granted from the computer by a admin-privileged user. If a parent did not authenticate, this represents the child suspending the filter themselves.`,
      severity: `recommended` as const,
      createdAt: new Date(now - 1000 * 60 * 60 * 5).toISOString(),
    },
    {
      case: `admin` as const,
      id: `5`,
      event: `Failed login`,
      explanation: `This event occurs whenever a parent fails to log into the parents admin website, usually from an incorrect password. Should be investigated if you do not recognize the failed attempt as your own.`,
      severity: `medium` as const,
      ipAddress: `98.45.123.77`,
      createdAt: new Date(now - 1000 * 60 * 60 * 8).toISOString(),
    },
    {
      case: `admin` as const,
      id: `6`,
      event: `Password changed`,
      explanation: `This event occurs when a parent changes their password for the parents admin site. Should be investigated if you did not change your password.`,
      severity: `recommended` as const,
      ipAddress: `107.205.36.96`,
      createdAt: new Date(now - 1000 * 60 * 60 * 24).toISOString(),
    },
    {
      case: `admin` as const,
      id: `7`,
      event: `Password reset requested`,
      explanation: `This event occurs when a parent requests a password reset for the parents admin site. Should be investigated if you did not request a password reset.`,
      severity: `recommended` as const,
      ipAddress: `107.205.36.96`,
      createdAt: new Date(now - 1000 * 60 * 60 * 25).toISOString(),
    },
    {
      case: `child` as const,
      id: `8`,
      childId: `child-2`,
      childName: `Harriet`,
      deviceId: `device-2`,
      deviceName: `New Blue`,
      event: `Filter suspension expired`,
      explanation: `This event occurs when a filter suspension ends after the scheduled time. It does not represent a safety risk.`,
      severity: `all` as const,
      createdAt: new Date(now - 1000 * 60 * 60 * 48).toISOString(),
    },
    {
      case: `child` as const,
      id: `9`,
      childId: `child-2`,
      childName: `Harriet`,
      deviceId: `device-2`,
      deviceName: `New Blue`,
      event: `Filter suspended remotely`,
      detail: `for 1 hr 29 min`,
      explanation: `This event occurs when a parent account accepts a request to suspend the filter. As long as the parent accepted the request, this event is normal.`,
      severity: `medium` as const,
      createdAt: new Date(now - 1000 * 60 * 60 * 72).toISOString(),
    },
  ],
  locations: {
    '107.205.36.96': { city: `Wadsworth`, region: `Ohio`, countryCode: `US` },
    '98.45.123.77': { city: `Chicago`, region: `Illinois`, countryCode: `US` },
  },
});

export const Empty: Story = props({
  events: [],
});

export default meta;
