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
    keychains: [],
    devices: [],
    createdAt: new Date().toISOString(),
  };

  beforeEach(() => {
    cy.simulateLoggedIn();
    cy.interceptPql(`GetAdmin`, {
      id: betsy.id,
      email: betsy.email,
      subscriptionStatus: { case: `paid` },
      notifications: [],
      verifiedNotificationMethods: [],
      hasAdminChild: false,
    });
    cy.interceptPql(`CreatePendingAppConnection`, { code: 123456 });
    cy.interceptPql(`GetUser`, leopold);
    cy.interceptPql(`GetUsers`, [leopold]);
    cy.interceptPql(`SaveUser`, { success: true });
    cy.interceptPql(`GetSelectableKeychains`, { own: [], public: [] });
  });

  it(`create first user from dashboard nudge`, () => {
    cy.interceptPql(`GetDashboardWidgets`, {
      // no users OR devices, so should see create first user prompt
      users: [],
      unlockRequests: [],
      userActivitySummaries: [],
      recentScreenshots: [],
      numAdminNotifications: 0,
    });

    cy.visit(`/`);
    cy.contains(`add a child that you’d like to protect`);
    cy.contains(`Add a child`).click();
    cy.location(`pathname`).should(`match`, /^\/children\/[a-f0-9-]{36}$/);

    cy.testId(`user-name`).type(`Leopold`);
    cy.contains(`Save child`).click();
    cy.contains(`need to do 2 steps`);
    cy.contains(`Get connection code`).click();
    cy.contains(`123456`).should(`be.visible`);
  });

  it(`connect device from dashboard nudge`, () => {
    cy.interceptPql(`GetDashboardWidgets`, {
      users: [
        {
          name: leopold.name,
          id: leopold.id,
          status: { case: `filterOn` },
          numDevices: 0, // <- child, but no devices
        },
      ],
      unlockRequests: [],
      userActivitySummaries: [],
      recentScreenshots: [],
      numAdminNotifications: 0,
    });

    cy.visit(`/`);
    cy.contains(`Congrats on adding your first child!`);
    cy.contains(`Get connection code`).click();
    cy.contains(`123456`).should(`be.visible`);
  });

  it(`recommends that you add a notification if there aren't any`, () => {
    cy.interceptPql(`GetDashboardWidgets`, {
      users: [
        {
          name: leopold.name,
          id: leopold.id,
          status: { case: `filterOn` },
          numDevices: 1,
        },
      ],
      unlockRequests: [],
      userActivitySummaries: [],
      recentScreenshots: [],
      numAdminNotifications: 0, // <-- no notifications
    });

    cy.visit(`/settings`);
    cy.contains(`No notifications`);
    cy.sidebarClick(`Dashboard`);
    cy.contains(`Create your first notification!`);
    cy.contains(`Create a notification`).click();
    cy.location(`pathname`).should(`eq`, `/settings`);
  });
});
