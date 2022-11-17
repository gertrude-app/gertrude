/// <reference types="cypress" />
import GetKeychain from '../fixtures/GetKeychain.json';
import GetIdentifiedApps from '../fixtures/GetIdentifiedApps.json';

describe(`create key flow`, () => {
  beforeEach(() => {
    cy.simulateLoggedIn();
    cy.viewport(1024, 875);
    cy.intercept(`/graphql/dashboard`, (req) => {
      switch (req.body.operationName) {
        case `GetIdentifiedApps`:
          req.reply(GetIdentifiedApps);
          break;
        case `GetKeychain`:
          req.reply(GetKeychain);
          break;
      }
    });
  });

  it(`handles entered domain with subdomain correctly`, () => {
    cy.visit(`/keychains/123`);
    cy.contains(`Add new key`).click();
    cy.contains(`Grant access to a specific website`).click();
    cy.testId(`keycreator-next-step`).click();
    cy.testId(`key-address`).type(`foo.bar.com`);

    cy.testId(`standard-registrable`)
      .should(`contain`, `bar.com`)
      .should(`not.contain`, `foo.bar.com`);

    cy.testId(`rotating-subdomains`).should(
      `have.attr`,
      `data-test-rotating-subdomains`,
      `foo,www,images,cdn,static,api`, // <-- includes `foo`
    );

    cy.testId(`address-type`).within(() => {
      cy.get(`button`).click();
      cy.contains(`Strict`).click();
    });

    cy.testId(`strict-hostname`)
      .should(`contain`, `foo.bar.com`)
      .should(`not.contain`, `www`);

    cy.testId(`rotating-subdomains`).should(
      `have.attr`,
      `data-test-rotating-subdomains`,
      `images,cdn,static,api,docs`,
    );
  });

  it(`handles entered domain with no subdomain correctly`, () => {
    cy.visit(`/keychains/123`);
    cy.contains(`Add new key`).click();
    cy.contains(`Grant access to a specific website`).click();
    cy.testId(`keycreator-next-step`).click();
    cy.testId(`key-address`).type(`bar.com`);

    cy.testId(`standard-registrable`)
      .should(`contain`, `bar.com`)
      .should(`not.contain`, `www.bar.com`);

    cy.testId(`rotating-subdomains`).should(
      `have.attr`,
      `data-test-rotating-subdomains`,
      `www,images,cdn,static,api`,
    );

    cy.testId(`address-type`).within(() => {
      cy.get(`button`).click();
      cy.contains(`Strict`).click();
    });

    cy.testId(`strict-apex`).should(`contain`, `bar.com`);
    cy.testId(`strict-www`).should(`contain`, `www.bar.com`);

    cy.testId(`rotating-subdomains`).should(
      `have.attr`,
      `data-test-rotating-subdomains`,
      `images,cdn,static,api,docs`,
    );
  });

  it(`gives useful hint when entering IP address wrongly`, () => {
    cy.visit(`/keychains/123`);
    cy.contains(`Add new key`).click();
    cy.contains(`Grant access to a specific website`).click();
    cy.testId(`keycreator-next-step`).click();
    cy.testId(`key-address`).type(`123.146.189.123`);
    cy.testId(`incorrect-ip-hint`).should(`exist`);
  });

  it(`prevents proceeding and gives useful hint when address invalid`, () => {
    cy.visit(`/keychains/123`);
    cy.contains(`Add new key`).click();
    cy.contains(`Grant access to a specific website`).click();
    cy.testId(`keycreator-next-step`).click();
    cy.testId(`key-address`).type(`foo`);
    cy.testId(`keycreator-next-step`).should(`be.disabled`);
  });

  // clicking escape in create key flow is trying to SAVE the key...
  // show unlockRequestAddress as reference
  // handle toggling strictness with untouched unlockRequestAddress, should not lose subdomain
});
