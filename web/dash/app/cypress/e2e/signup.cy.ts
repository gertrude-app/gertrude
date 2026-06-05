/// <reference types="cypress" />
import { betsy } from '../fixtures/helpers';

describe(`signup`, () => {
  // NB: we let as many requests go to origin for this flow as possible
  it(`handles signup flow`, () => {
    cy.visit(`/signup`);
    const email = `e2e-user-${Date.now()}@gertrude.app`;
    cy.get(`input[name=email]`).type(email);
    cy.get(`input[name=password]`).type(`bobbobbob{enter}`);
    cy.contains(`Verification email sent`);

    // logging in before email verification should not work
    cy.visit(`/login`);
    cy.get(`input[name=email]`).type(email);
    cy.get(`input[name=password]`).type(`bobbobbob{enter}`);
    cy.contains(`until your email is verified`);

    // we can't click an email verify link, so intercept from here out
    cy.interceptPql(`VerifySignupEmail`, {
      adminId: `admin-123`,
      token: `token-123`,
    });

    cy.interceptPql(`DashboardWidgets_v2`, {
      children: [],
      unlockRequests: [],
      childActivitySummaries: [],
      recentScreenshots: [],
      numParentNotifications: 0,
      pendingIOSDevices: [],
    });

    cy.visit(`/verify-signup-email/verify-token-123`);

    cy.wait(`@VerifySignupEmail`)
      .its(`request.body`)
      .should(`deep.eq`, { token: `verify-token-123` });

    cy.interceptPql(`LogEvent`, { success: true });

    cy.contains(`I’m a parent`).click();

    cy.wait(`@LogEvent`).then(({ request }) => {
      expect(request.body.detail).to.contain(`PARENT-CHILD`);
    });

    cy.wait(`@DashboardWidgets_v2`)
      .its(`request.headers.${`X-AdminToken`.toLowerCase()}`)
      .should(`eq`, `token-123`);

    cy.contains(`Welcome to Gertrude!`).then(() => {
      expect(localStorage.getItem(`admin_id`)).to.eq(`admin-123`);
      expect(localStorage.getItem(`admin_token`)).to.eq(`token-123`);
    });
  });

  it(`handles account deletion for wrong use case`, () => {
    cy.interceptPql(`LogEvent`, { success: true });
    cy.interceptPql(`DeleteEntity_v2`, { success: true });
    cy.simulateLoggedIn();
    cy.visit(`/use-case`);

    cy.contains(`help myself`).click();

    cy.wait(`@LogEvent`).then(({ request }) => {
      expect(request.body.detail).to.contain(`SELF`);
    });

    cy.contains(`Delete my account`).click();

    cy.wait(`@DeleteEntity_v2`)
      .its(`request.body`)
      .should(`deep.eq`, { id: betsy.id, type: `parent` });

    cy.contains(`Account deleted!`);
  });
});

describe(`app-aware claim glue`, () => {
  it(`shows the Gertrude AM app card + "Signup to connect:" for an AM claim`, () => {
    cy.visit(
      `/signup?claimPendingAmDevice=778899&modelName=iPhone+15+Pro&iosVersion=18.2`,
    );
    cy.contains(`Signup to connect:`);
    cy.contains(`iPhone 15 Pro`);
    cy.contains(`For app:`);
    cy.contains(`Gertrude AM`);
  });

  it(`still shows the Gertrude Blocker app card for a supervision claim`, () => {
    cy.visit(
      `/signup?claimPendingSupervision=123456&modelName=iPhone+15+Pro&iosVersion=18.2`,
    );
    cy.contains(`Signup to connect:`);
    cy.contains(`iPhone 15 Pro`);
    cy.contains(`Gertrude Blocker`);
  });
});

describe(`verify-signup-email post-verify routing`, () => {
  it(`routes to the AM funnel when a redirect param is present`, () => {
    cy.interceptPql(`VerifySignupEmail`, { adminId: `admin-123`, token: `token-123` });
    cy.interceptPql(`GetAmClaimData`, {
      children: [],
      modelName: `iPhone 15 Pro`,
      deviceType: `iPhone`,
      iosVersion: `18.2`,
    });

    cy.visit(
      `/verify-signup-email/verify-token-123?redirect=${encodeURIComponent(
        `/claim-am-device/778899/claim`,
      )}`,
    );

    cy.wait(`@VerifySignupEmail`);
    cy.location(`pathname`).should(`eq`, `/claim-am-device/778899/claim`);
  });

  it(`falls back to the supervision funnel for a legacy claimCode-only verify`, () => {
    cy.interceptPql(`VerifySignupEmail`, {
      adminId: `admin-123`,
      token: `token-123`,
      claimCode: `123456`,
    });
    cy.interceptPql(`GetIOSDeviceClaimData`, {
      children: [],
      modelName: `iPhone 15 Pro`,
      deviceType: `iPhone`,
      iosVersion: `18.2`,
    });

    cy.visit(`/verify-signup-email/verify-token-123`);

    cy.wait(`@VerifySignupEmail`);
    cy.location(`pathname`).should(`eq`, `/supervise-device/123456/claim`);
  });

  it(`routes to /use-case when there is neither a redirect nor a claimCode`, () => {
    cy.interceptPql(`VerifySignupEmail`, { adminId: `admin-123`, token: `token-123` });

    cy.visit(`/verify-signup-email/verify-token-123`);

    cy.wait(`@VerifySignupEmail`);
    cy.location(`pathname`).should(`eq`, `/use-case`);
  });
});

describe(`payment`, () => {
  it(`return from stripe success`, () => {
    cy.simulateLoggedIn();
    cy.interceptPql(`HandleCheckoutSuccess`, { success: true });

    cy.visit(`/checkout-success?session_id=cs_test_123`);

    cy.wait(`@HandleCheckoutSuccess`)
      .its(`request.body`)
      .should(`deep.eq`, { stripeCheckoutSessionId: `cs_test_123` });

    cy.contains(`Payment setup complete`);
  });

  it(`return from stripe cancel`, () => {
    cy.simulateLoggedIn();
    cy.interceptPql(`HandleCheckoutCancel`, { success: true });

    cy.visit(`/checkout-cancel?session_id=cs_test_123`);

    cy.wait(`@HandleCheckoutCancel`)
      .its(`request.body`)
      .should(`deep.eq`, { stripeCheckoutSessionId: `cs_test_123` });

    cy.contains(`Payment setup cancelled`);
  });

  it(`fetching billing portal url`, () => {
    cy.simulateLoggedIn();
    cy.interceptPql(`GetAccountOwner_v2`, {
      id: betsy.id,
      email: betsy.email,
      notifications: [],
      verifiedNotificationMethods: [],
    });

    cy.interceptPql(`GetSubscriptionPanel_v2`, {
      planStatus: {
        case: `full`,
        status: { case: `current`, renewsAt: new Date().toISOString() },
      },
      primary: { case: `openBillingPortal`, config: `default` },
      secondary: [],
      availableTiers: [],
    });

    cy.interceptPql(`OpenBillingPortal`, { url: `/stripe-url` });

    cy.visit(`/settings`);
    cy.contains(`Manage plan`).click();
    cy.contains(`Manage subscription`).click();

    cy.wait(`@OpenBillingPortal`)
      .its(`request.body`)
      .should(`deep.eq`, { returnPath: `/settings`, configuration: `default` });
  });
});
