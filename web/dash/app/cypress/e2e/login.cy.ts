/// <reference types="cypress" />
import { betsy } from '../fixtures/helpers';

describe(`dashboard app login`, () => {
  beforeEach(() => {
    cy.interceptPql(`RequestMagicLink`, { success: true });
  });

  describe(`standard login procedures`, () => {
    it(`handles happy path`, () => {
      cy.visit(`/login`);
      cy.get(`input[name=email]`).type(betsy.email);
      cy.get(`input[name=password]`).type(`${betsy.password}{enter}`);
      cy.location(`pathname`).should(`eq`, `/`);
      cy.contains(`Little Jimmy`).should(() => {
        expect(localStorage.getItem(`admin_id`)).to.eq(betsy.id);
        expect(localStorage.getItem(`admin_token`)).to.match(/^[0-9a-f-]{36}$/);
      });
    });

    it(`handles wrong password`, () => {
      cy.visit(`/login`);
      cy.get(`input[name=email]`).type(betsy.email);
      cy.get(`input[name=password]`).type(`bad{enter}`);
      cy.location(`pathname`).should(`eq`, `/login`);
      cy.contains(`Incorrect`);
    });

    it(`handles magic-link`, () => {
      cy.visit(`/login`);
      cy.testId(`magic-link`).should(`be.disabled`);
      cy.get(`input[name=email]`).type(betsy.email);
      cy.testId(`magic-link`).should(`not.be.disabled`).click();

      cy.wait(`@RequestMagicLink`).its(`request.body.email`).should(`eq`, betsy.email);

      cy.contains(`Check your email`);
    });

    it(`handles magic-link with redirect`, () => {
      cy.visit(`/login?redirect=${encodeURIComponent(`/children/123`)}`);
      cy.get(`input[name=email]`).type(betsy.email);
      cy.testId(`magic-link`).click();

      cy.wait(`@RequestMagicLink`)
        .its(`request.body`)
        .should(`deep.equal`, { email: betsy.email, redirect: `/children/123` });

      cy.contains(`Check your email`);
    });

    it(`redirects to / if admin is already logged in`, () => {
      cy.simulateLoggedIn();
      cy.visit(`/login`);
      cy.contains(`Dashboard`);
    });

    it(`redirects to intended location after login (missing admin tokens)`, () => {
      cy.visit(`/children`);
      cy.url().should(`include`, `/login`);
      cy.get(`input[name=email]`).type(`82uii.betsy-mcstandard@inbox.testmail.app`);
      cy.get(`input[name=password]`).type(`betsy123{enter}`);
      cy.location(`pathname`).should(`eq`, `/children`);
    });

    it(`redirects to intended location after login (expired admin tokens)`, () => {
      localStorage.setItem(`admin_id`, betsy.id);
      localStorage.setItem(`admin_token`, `deadbeef-dead-beef-dead-beefdeadbeef`);
      cy.visit(`/children`);
      cy.url().should(`include`, `/login`);
      cy.get(`input[name=email]`).type(`82uii.betsy-mcstandard@inbox.testmail.app`);
      cy.get(`input[name=password]`).type(`betsy123{enter}`);
      cy.location(`pathname`).should(`eq`, `/children`);
    });
  });

  describe(`password reset`, () => {
    it(`shows email sent confirmation when no error`, () => {
      cy.interceptPql(`SendPasswordResetEmail`, { success: true });
      cy.visit(`/login`);
      cy.contains(`Forgot password?`).click();
      cy.location(`pathname`).should(`eq`, `/reset-password`);
      cy.contains(`Reset your password`);
      cy.get(`input[type=email]`).type(betsy.email);
      cy.contains(`Send reset link`).click();
      cy.contains(`Email sent!`).should(`be.visible`);
    });

    it(`logs admin back in after password reset`, () => {
      cy.interceptPql(`ResetPassword`, { success: true });
      cy.visit(`/reset-password/123`);
      cy.contains(`Choose a new password`);
      cy.get(`input[type=password]`).type(`super_secret?`);
      cy.contains(`Log in`).click();
      cy.contains(`Password successfully changed!`);
    });

    it(`shows error when password reset fails due to invalid token`, () => {
      cy.interceptPql(`ResetPassword`, { success: false });
      cy.visit(`/reset-password/123`);
      cy.contains(`Choose a new password`);
      cy.get(`input[type=password]`).type(`super_secret?`);
      cy.contains(`Log in`).click();
      cy.contains(`Uh-oh!`);
      cy.contains(`Token expired`);
    });
  });
});
