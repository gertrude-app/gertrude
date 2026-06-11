/// <reference types="cypress" />

describe(`referral signup attribution`, () => {
  it(`sends referral attribution from the query before the cookie`, () => {
    cy.interceptPql(`Signup`, {});
    cy.setCookie(`referral_code`, `COOKIE-CODE`);
    cy.visit(`/signup?ref=QUERY-CODE`);
    cy.get(`input[name=email]`).type(`query-referral@example.com`);
    cy.get(`input[name=password]`).type(`bobbobbob{enter}`);

    cy.wait(`@Signup`).its(`request.body.referralCode`).should(`eq`, `QUERY-CODE`);
  });

  it(`falls back to referral attribution from the cookie`, () => {
    cy.interceptPql(`Signup`, {});
    cy.setCookie(`referral_code`, `COOKIE-CODE`);
    cy.visit(`/signup`);
    cy.get(`input[name=email]`).type(`cookie-referral@example.com`);
    cy.get(`input[name=password]`).type(`bobbobbob{enter}`);

    cy.wait(`@Signup`).its(`request.body.referralCode`).should(`eq`, `COOKIE-CODE`);
  });
});
