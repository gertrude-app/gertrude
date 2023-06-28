/// <reference types="cypress" />
import { betsy } from '../fixtures/helpers';

describe(`signup`, () => {
  it(`handles signup flow, minus stripe redirect`, () => {
    // use betsy's id for stripe direct checkout test
    cy.interceptPql(`VerifySignupEmail`, { adminId: betsy.id });

    // prevent trying to go to stripe, which causes cross-origin issues
    cy.forcePqlErr(`GetCheckoutUrl`);

    cy.visit(`/signup`);
    cy.get(`input[name=email]`).type(`e2e-test-${Date.now()}@gertrude.app`);
    cy.get(`input[name=password]`).type(`bobbobbob{enter}`);
    cy.contains(`Verification email sent`);

    cy.visit(`/verify-signup-email/123`);
    cy.contains(`error`); // forced error above, to prevent redirect
  });

  it(`sends correct mutation and auto logs-in on success`, () => {
    cy.interceptPql(`HandleCheckoutSuccess`, {
      token: `token-123`,
      adminId: `admin-123`,
    });

    cy.interceptPql(`GetDashboardWidgets`, {
      users: [],
      unlockRequests: [],
      userActivitySummaries: [],
      recentScreenshots: [],
    });

    cy.visit(`/checkout-success?session_id=cs_test_123`);

    cy.wait(`@HandleCheckoutSuccess`)
      .its(`request.body.stripeCheckoutSessionId`)
      .should(`eq`, `cs_test_123`);

    cy.wait(`@GetDashboardWidgets`)
      .its(`request.headers.${`X-AdminToken`.toLowerCase()}`)
      .should(`eq`, `token-123`);

    cy.contains(`Welcome to Gertrude!`).then(() => {
      expect(localStorage.getItem(`admin_id`)).to.eq(`admin-123`);
      expect(localStorage.getItem(`admin_token`)).to.eq(`token-123`);
    });
  });
});
