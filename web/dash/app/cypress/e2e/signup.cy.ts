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

    cy.interceptPql(`DashboardWidgets_v3`, {
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

    cy.contains(`A friend or family member`).click();

    cy.wait(`@LogEvent`).then(({ request }) => {
      expect(request.body.detail).to.contain(`friend_family`);
    });

    cy.wait(`@DashboardWidgets_v3`)
      .its(`request.headers.${`X-AdminToken`.toLowerCase()}`)
      .should(`eq`, `token-123`);

    cy.contains(`Welcome to Gertrude!`).then(() => {
      expect(localStorage.getItem(`admin_id`)).to.eq(`admin-123`);
      expect(localStorage.getItem(`admin_token`)).to.eq(`token-123`);
    });
  });
});

describe(`app-aware claim glue`, () => {
  it(`shows the Gertrude Podcasts app card + "Signup to connect:" for a podcasts claim`, () => {
    cy.visit(
      `/signup?claimPendingPodcastsDevice=778899&modelName=iPhone+15+Pro&iosVersion=18.2`,
    );
    cy.contains(`Signup to connect:`);
    cy.contains(`iPhone 15 Pro`);
    cy.contains(`For app:`);
    cy.contains(`Gertrude Podcasts`);
  });

  it(`shows the Gertrude Music app card + "Signup to connect:" for a Music claim`, () => {
    cy.visit(
      `/signup?claimPendingMusicDevice=778899&modelName=iPhone+15+Pro&iosVersion=18.2`,
    );
    cy.contains(`Signup to connect:`);
    cy.contains(`iPhone 15 Pro`);
    cy.contains(`For app:`);
    cy.contains(`Gertrude Music`);
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

describe(`logged-out claim deep-link bounce`, () => {
  it(`recovers a legacy AM claim deep-link via the api claim redirect (backwards compat)`, () => {
    cy.intercept(`**/claim-pending-podcasts/778899`, {
      statusCode: 307,
      headers: {
        location: `${Cypress.config().baseUrl}/signup?claimPendingAmDevice=778899&modelName=iPhone+15+Pro&iosVersion=18.2&redirect=${encodeURIComponent(
          `/claim-am-device/778899/claim`,
        )}`,
      },
    });

    cy.visit(`/claim-am-device/778899/claim`);

    cy.location(`pathname`).should(`eq`, `/signup`);
    cy.contains(`Signup to connect:`);
    cy.contains(`iPhone 15 Pro`);
    cy.contains(`Gertrude Podcasts`);

    cy.interceptPql(`Signup`, {});
    cy.get(`input[name=email]`).type(`am-claim@example.com`);
    cy.get(`input[name=password]`).type(`bobbobbob{enter}`);

    cy.wait(`@Signup`) // claim context must reach the signup payload
      .its(`request.body`)
      .should(`include`, { claimCode: `778899`, intent: `podcasts` });
    cy.contains(`Verification email sent`);
  });

  it(`recovers a supervision claim deep-link via the api claim redirect`, () => {
    cy.intercept(`**/claim-pending-supervision/123456`, {
      statusCode: 307,
      headers: {
        location: `${Cypress.config().baseUrl}/signup?claimPendingSupervision=123456&modelName=iPhone+15+Pro&iosVersion=18.2&redirect=${encodeURIComponent(
          `/supervise-device/123456/claim`,
        )}`,
      },
    });

    cy.visit(`/supervise-device/123456/claim`);

    cy.location(`pathname`).should(`eq`, `/signup`);
    cy.contains(`Signup to connect:`);
    cy.contains(`Gertrude Blocker`);

    cy.interceptPql(`Signup`, {});
    cy.get(`input[name=email]`).type(`supervision-claim@example.com`);
    cy.get(`input[name=password]`).type(`bobbobbob{enter}`);

    cy.wait(`@Signup`)
      .its(`request.body`)
      .should(`include`, { claimCode: `123456`, intent: `blockerSupervise` });
    cy.contains(`Verification email sent`);
  });
});

describe(`verify-signup-email post-verify routing`, () => {
  it(`continues to the AM funnel through the referral survey when a redirect param is present`, () => {
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
    cy.location(`pathname`).should(`eq`, `/referral-survey`);
    cy.contains(`Skip`).click();
    cy.location(`pathname`).should(`eq`, `/claim-am-device/778899/claim`);
  });

  it(`routes to the Music funnel through the referral survey when a redirect param is present`, () => {
    cy.interceptPql(`VerifySignupEmail`, { adminId: `admin-123`, token: `token-123` });
    cy.interceptPql(`GetMusicClaimData`, {
      children: [],
      modelName: `iPhone 15 Pro`,
      deviceType: `iPhone`,
      iosVersion: `18.2`,
    });

    cy.visit(
      `/verify-signup-email/verify-token-123?redirect=${encodeURIComponent(
        `/claim-music-device/778899/claim`,
      )}`,
    );

    cy.wait(`@VerifySignupEmail`);
    cy.location(`pathname`).should(`eq`, `/referral-survey`);
    cy.contains(`Skip`).click();
    cy.location(`pathname`).should(`eq`, `/claim-music-device/778899/claim`);
  });

  it(`continues to the podcasts funnel from token claim data when the redirect param is missing`, () => {
    cy.interceptPql(`VerifySignupEmail`, {
      adminId: `admin-123`,
      token: `token-123`,
      claimCode: `778899`,
      claimIntent: `podcasts`,
    });
    cy.interceptPql(`GetAmClaimData`, {
      children: [],
      modelName: `iPhone 15 Pro`,
      deviceType: `iPhone`,
      iosVersion: `18.2`,
    });

    cy.visit(`/verify-signup-email/verify-token-123`);

    cy.wait(`@VerifySignupEmail`);
    cy.location(`pathname`).should(`eq`, `/referral-survey`);
    cy.contains(`Skip`).click();
    cy.location(`pathname`).should(`eq`, `/claim-podcasts-device/778899/claim`);
  });

  it(`continues to the supervision funnel through the referral survey for a legacy claimCode-only verify`, () => {
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
    cy.location(`pathname`).should(`eq`, `/referral-survey`);
    cy.contains(`Skip`).click();
    cy.location(`pathname`).should(`eq`, `/supervise-device/123456/claim`);
  });

  it(`routes to the referral survey when there is neither a redirect nor a claimCode`, () => {
    cy.interceptPql(`VerifySignupEmail`, { adminId: `admin-123`, token: `token-123` });

    cy.visit(`/verify-signup-email/verify-token-123`);

    cy.wait(`@VerifySignupEmail`);
    cy.location(`pathname`).should(`eq`, `/referral-survey`);
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
      dailyReviewEmail: false,
      hasMacScreenshotUsers: true,
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
