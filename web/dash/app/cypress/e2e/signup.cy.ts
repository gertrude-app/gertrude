/// <reference types="cypress" />
import { betsy } from '../fixtures/helpers';

describe(`signup`, () => {
  it(`handles signup flow, minus stripe redirect`, () => {
    let checkoutUrl = ``;

    cy.intercept(`/pairql/dashboard/VerifySignupEmail`, (req) => {
      // use betsy's id for stripe direct checkout test
      req.reply({ adminId: betsy.id });
    });

    cy.intercept(`/pairql/dashboard/GetCheckoutUrl`, (req) => {
      req.alias = `getCheckoutUrl`;
      req.reply((res) => {
        checkoutUrl = res.body.url;
        res.body = { error: {}, __cyStubbedError: true };
      });
    });

    cy.visit(`/signup`);
    cy.get(`input[name=email]`).type(`e2e-test-${Date.now()}@gertrude.app`);
    cy.get(`input[name=password]`).type(`bobbobbob{enter}`);
    cy.contains(`Verification email sent`);

    cy.visit(`/verify-signup-email/123`);
    cy.wait(`@getCheckoutUrl`).then(() => {
      cy.writeFile(`cypress/screenshots/checkoutUrl.json`, { url: checkoutUrl });
    });

    cy.contains(`error`); // forced error above, to prevent redirect
  });

  it(`gets a valid stripe checkout url back from api`, () => {
    cy.readFile(`cypress/screenshots/checkoutUrl.json`).then(({ url }) => {
      expect(url).to.match(/^https:\/\/checkout.stripe.com/);
      cy.visit(url);
      cy.contains(`Gertrude`);
      cy.contains(`60 days free`);
      cy.contains(`Then $5.00 per month`);
      cy.contains(`Start trial`);
      cy.contains(`betsy-mcstandard`); // because we spoofed her id above
      cy.contains(`Card information`).should(`not.exist`);
    });
  });

  it(`sends correct mutation and auto logs-in on success`, () => {
    cy.intercept(`/pairql/dashboard/HandleCheckoutSuccess`, (req) => {
      req.alias = `signup`;
      req.reply({ token: `token-123`, adminId: `admin-123` });
    });

    cy.intercept(`/pairql/dashboard/GetDashboardWidgets`, (req) => {
      req.alias = `widgets`;
      req.reply({ unlockRequests: [], users: [], userActivity: [], userScreenshots: [] });
    });

    cy.visit(`/checkout-success?session_id=cs_test_123`);

    cy.wait(`@signup`)
      .its(`request.body.stripeCheckoutSessionId`)
      .should(`eq`, `cs_test_123`);

    cy.wait(`@widgets`)
      .its(`request.headers.${`X-AdminToken`.toLowerCase()}`)
      .should(`eq`, `token-123`);

    cy.contains(`Welcome to Gertrude!`).then(() => {
      expect(localStorage.getItem(`admin_id`)).to.eq(`admin-123`);
      expect(localStorage.getItem(`admin_token`)).to.eq(`token-123`);
    });
  });
});
