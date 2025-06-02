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

    cy.interceptPql(`DashboardWidgets`, {
      children: [],
      unlockRequests: [],
      childActivitySummaries: [],
      recentScreenshots: [],
      numParentNotifications: 0,
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

    cy.wait(`@DashboardWidgets`)
      .its(`request.headers.${`X-AdminToken`.toLowerCase()}`)
      .should(`eq`, `token-123`);

    cy.contains(`Welcome to the parent website!`).then(() => {
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

  it(`fetching stripe url`, () => {
    cy.simulateLoggedIn();
    cy.interceptPql(`GetAdmin`, {
      id: betsy.id,
      email: betsy.email,
      subscriptionStatus: { case: `paid` },
      notifications: [],
      verifiedNotificationMethods: [],
      hasAdminChild: false,
    });

    cy.interceptPql(`StripeUrl`, { url: `/stripe-url` });

    cy.visit(`/settings`);
    cy.contains(`Manage subscription`).click();
    cy.contains(`Click here!`).should(`have.attr`, `href`, `/stripe-url`);
  });
});
