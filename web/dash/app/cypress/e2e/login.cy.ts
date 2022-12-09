/// <reference types="cypress" />
import { betsy } from '../fixtures/helpers';

describe(`dashboard app login`, () => {
  beforeEach(() => {
    cy.intercept(`/graphql/dashboard`, (req) => {
      switch (req.body.operationName) {
        case `RequestMagicLink`:
          req.alias = `requestMagicLink`;
          req.reply({ data: { result: { success: true } } });
          break;
      }
    });
  });

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
    cy.contains(`incorrect`);
  });

  it(`handles magic-link`, () => {
    cy.visit(`/login`);
    cy.testId(`magic-link`).should(`be.disabled`);
    cy.get(`input[name=email]`).type(betsy.email);
    cy.testId(`magic-link`).should(`not.be.disabled`).click();

    cy.wait(`@requestMagicLink`)
      .its(`request.body.variables.email`)
      .should(`eq`, betsy.email);

    cy.contains(`Check your email`);
  });

  it(`handles magic-link with redirect`, () => {
    cy.visit(`/login?redirect=${encodeURIComponent(`/users/123`)}`);
    cy.get(`input[name=email]`).type(betsy.email);
    cy.testId(`magic-link`).click();

    cy.wait(`@requestMagicLink`)
      .its(`request.body.variables`)
      .should(`deep.equal`, { email: betsy.email, redirect: `/users/123` });

    cy.contains(`Check your email`);
  });
});
