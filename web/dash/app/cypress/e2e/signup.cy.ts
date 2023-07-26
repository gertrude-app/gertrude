/// <reference types="cypress" />

describe(`signup`, () => {
  beforeEach(() => {
    cy.interceptPql(`GetDashboardWidgets`, {
      users: [],
      unlockRequests: [],
      userActivitySummaries: [],
      recentScreenshots: [],
      numAdminNotifications: 0,
    });
  });

  it(`handles signup flow, minus stripe redirect`, () => {
    cy.interceptPql(`VerifySignupEmail`, {
      adminId: `admin-123`,
      token: `token-123`,
    });

    cy.interceptPql(`Signup`, {});

    cy.visit(`/signup`);
    cy.get(`input[name=email]`).type(`new-user@example.com`);
    cy.get(`input[name=password]`).type(`bobbobbob{enter}`);

    cy.wait(`@Signup`).its(`request.body`).should(`deep.eq`, {
      email: `new-user@example.com`,
      password: `bobbobbob`,
    });
    cy.contains(`Verification email sent`);

    cy.visit(`/verify-signup-email/ephemeral-123`);

    cy.wait(`@VerifySignupEmail`)
      .its(`request.body`)
      .should(`deep.eq`, { token: `ephemeral-123` });

    cy.wait(`@GetDashboardWidgets`)
      .its(`request.headers.${`X-AdminToken`.toLowerCase()}`)
      .should(`eq`, `token-123`);

    cy.contains(`Welcome to the parent website!`).then(() => {
      expect(localStorage.getItem(`admin_id`)).to.eq(`admin-123`);
      expect(localStorage.getItem(`admin_token`)).to.eq(`token-123`);
    });
  });
});
