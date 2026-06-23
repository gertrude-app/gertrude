/// <reference types="cypress" />
import { betsy } from '../fixtures/helpers';

describe(`dashboard onboarding nudges`, () => {
  const leopold = {
    id: `user-123`,
    name: `Leopold`,
    keyloggingEnabled: true,
    screenshotsEnabled: false,
    screenshotsResolution: 1200,
    screenshotsFrequency: 30,
    showSuspensionActivity: true,
    filteringDisabled: false,
    canDisableFilter: false,
    keychains: [],
    computers: [],
    iosDevices: [],
    availableAlwaysBlockedGroups: [],
    alwaysBlockedGroupIds: [],
    customAlwaysBlockedRules: [],
    supportsAlwaysBlocked: false,
    createdAt: new Date().toISOString(),
  };

  beforeEach(() => {
    cy.simulateLoggedIn();
    cy.interceptPql(`GetAccountOwner_v2`, {
      id: betsy.id,
      email: betsy.email,
      dailyReviewEmail: false,
      hasMacScreenshotUsers: true,
      notifications: [],
      verifiedNotificationMethods: [],
    });
    cy.interceptPql(`MacAppConnectionCode`, { code: 123456 });
    cy.interceptPql(`GetChild`, leopold);
    cy.interceptPql(`GetChildren`, [leopold]);
    cy.interceptPql(`GetSubscriptionPanel_v2`, {
      planStatus: {
        case: `full`,
        status: { case: `current`, renewsAt: new Date().toISOString() },
      },
      primary: { case: `openBillingPortal`, config: `default` },
      secondary: [],
      availableTiers: [],
    });
    cy.interceptPql(`SaveUser`, { success: true });
    cy.interceptPql(`GetSelectableKeychains`, { own: [], public: [] });
  });

  it(`create first user from dashboard nudge`, () => {
    cy.interceptPql(`DashboardWidgets_v3`, {
      // no users OR devices, so should see create first user prompt
      children: [],
      unlockRequests: [],
      childActivitySummaries: [],
      recentScreenshots: [],
      numParentNotifications: 0,
      pendingIOSDevices: [],
    });

    cy.visit(`/`);
    cy.contains(`Mac computer`).click();
    cy.contains(`Add a child`).click();
    cy.location(`pathname`).should(`match`, /^\/children\/[a-f0-9-]{36}$/);

    cy.testId(`user-name`).type(`Leopold`);
    cy.contains(`Save child`).click();
    cy.contains(`Mac computer`).click();
    cy.contains(`need to do 2 steps`);
    cy.contains(`Get connection code`).click();
    cy.contains(`123456`).should(`be.visible`);
  });

  it(`connect device from dashboard nudge`, () => {
    cy.interceptPql(`DashboardWidgets_v3`, {
      children: [
        {
          name: leopold.name,
          id: leopold.id,
          devices: [], // <- child, but no devices
        },
      ],
      unlockRequests: [],
      childActivitySummaries: [],
      recentScreenshots: [],
      numParentNotifications: 0,
      pendingIOSDevices: [],
    });

    cy.visit(`/`);
    cy.contains(`What type of device will Leopold be using?`);
    cy.contains(`Mac computer`).click();
    cy.contains(`Get connection code`).click();
    cy.contains(`123456`).should(`be.visible`);
  });

  it(`recommends that you add a notification if there aren't any`, () => {
    cy.interceptPql(`DashboardWidgets_v3`, {
      children: [
        {
          name: leopold.name,
          id: leopold.id,
          devices: [
            {
              platform: `mac`,
              deviceName: `MacBook Pro`,
              macStatus: { case: `filterOn` },
            },
          ],
        },
      ],
      unlockRequests: [],
      childActivitySummaries: [],
      recentScreenshots: [],
      numParentNotifications: 0, // <-- no notifications
      pendingIOSDevices: [],
    });

    cy.visit(`/settings`);
    cy.contains(`No notifications`);
    cy.sidebarClick(`Dashboard`);
    cy.contains(`Create your first notification!`);
    cy.contains(`Create a notification`).click();
    cy.location(`pathname`).should(`eq`, `/settings`);
  });
});
