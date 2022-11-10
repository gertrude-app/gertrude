/// <reference types="cypress" />

describe(`dashboard app login`, () => {
  it(`handles happy path`, () => {
    cy.visit(`/login`);
    cy.get(`input[name=email]`).type(`82uii.betsy-mcstandard@inbox.testmail.app`);
    cy.get(`input[name=password]`).type(`betsy123{enter}`);
    cy.contains(`Dashboard`).should(() => {
      expect(localStorage.getItem(`admin_id`)).to.eq(
        `be000000-0000-0000-0000-000000000000`,
      );
      expect(localStorage.getItem(`admin_token`)).to.match(/^[0-9a-f-]{36}$/);
    });
    cy.contains(`Little Jimmy`);
  });

  it(`handles wrong password`, () => {
    cy.visit(`/login`);
    cy.get(`input[name=email]`).type(`82uii.betsy-mcstandard@inbox.testmail.app`);
    cy.get(`input[name=password]`).type(`bad{enter}`);
    cy.url().should(`include`, `/login`);
    cy.contains(`incorrect`);
  });

  it(`handles magic-link`, () => {
    cy.visit(`/login`);
    cy.get(`[data-test="magic-link"]`).should(`be.disabled`);
    cy.get(`input[name=email]`).type(`82uii.betsy-mcstandard@inbox.testmail.app`);
    cy.get(`[data-test="magic-link"]`).should(`not.be.disabled`);

    // todo: would be good to test actual email/otp flow here...
  });
});
