/// <reference types="cypress" />

describe(`signup`, () => {
  // NB: we let as many requests go to origin for this flow as possible
  it(`handles signup flow, minus stripe redirect`, () => {
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

    cy.interceptPql(`GetDashboardWidgets`, {
      users: [],
      unlockRequests: [],
      userActivitySummaries: [],
      recentScreenshots: [],
      numAdminNotifications: 0,
    });

    cy.visit(`/verify-signup-email/verify-token-123`);

    cy.wait(`@VerifySignupEmail`)
      .its(`request.body`)
      .should(`deep.eq`, { token: `verify-token-123` });

    cy.wait(`@GetDashboardWidgets`)
      .its(`request.headers.${`X-AdminToken`.toLowerCase()}`)
      .should(`eq`, `token-123`);

    cy.contains(`Welcome to the parent website!`).then(() => {
      expect(localStorage.getItem(`admin_id`)).to.eq(`admin-123`);
      expect(localStorage.getItem(`admin_token`)).to.eq(`token-123`);
    });
  });
});
