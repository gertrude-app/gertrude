import { describe, expect, test } from 'vitest';
import type { GetAccountSettings } from '@shared/pairql/src/account';
import { notificationMethodInput, notificationSettingsViewModel } from '../settings';

const settings: GetAccountSettings.Output = {
  email: `parent@example.com`,
  dailyReviewEmail: true,
  hasMacScreenshotUsers: true,
  notificationMethods: [
    {
      id: `method-email`,
      config: { case: `email`, email: `parent@example.com` },
    },
    {
      id: `method-ntfy`,
      config: { case: `ntfy`, topic: `gertrude-family-topic` },
    },
  ],
  notifications: [
    {
      id: `notification-email`,
      methodId: `method-email`,
      trigger: `unlockRequestSubmitted`,
    },
    {
      id: `notification-missing-method`,
      methodId: `missing`,
      trigger: `securityEventsAll`,
    },
  ],
};

describe(`account settings mapping`, () => {
  test(`joins notifications to their verified methods`, () => {
    const output = notificationSettingsViewModel(settings);

    expect(output.notificationMethods).toEqual([
      {
        id: `method-email`,
        type: `email`,
        emailAddress: `parent@example.com`,
      },
      {
        id: `method-ntfy`,
        type: `ntfy`,
        topicId: `gertrude-family-topic`,
      },
    ]);
    expect(output.notifications).toEqual([
      {
        id: `notification-email`,
        methodId: `method-email`,
        trigger: `unlockRequestSubmitted`,
        method: {
          id: `method-email`,
          type: `email`,
          emailAddress: `parent@example.com`,
        },
      },
    ]);
  });

  test(`converts method drafts to PairQL inputs`, () => {
    expect(
      notificationMethodInput({
        type: `slack`,
        channelName: `alerts`,
        channelId: `C123`,
        botToken: `xoxb-test`,
      }),
    ).toEqual({
      case: `slack`,
      channelName: `alerts`,
      channelId: `C123`,
      token: `xoxb-test`,
    });
    expect(notificationMethodInput({ type: `ntfy` })).toEqual({
      case: `ntfy`,
      topic: ``,
    });
  });
});
