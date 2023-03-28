/// <reference types="cypress" />
import type { AdminKeychain, GetIdentifiedApps } from '@dash/types';

describe(`create key flow`, () => {
  beforeEach(() => {
    cy.simulateLoggedIn();
    cy.viewport(1024, 875);

    cy.intercept(`/pairql/dashboard/GetIdentifiedApps`, (req) => {
      const app: GetIdentifiedApps.Output[number] = {
        id: `app-123`,
        name: `Brave`,
        slug: `brave`,
        selectable: true,
        bundleIds: [],
      };
      req.reply([app]);
    });

    cy.intercept(`/pairql/dashboard/GetAdminKeychain`, (req) => {
      const keychain: AdminKeychain = {
        summary: {
          id: `123`,
          name: `Betsy's Keychain`,
          authorId: `admin-123`,
          isPublic: false,
          numKeys: 0,
        },
        keys: [],
      };
      req.reply(keychain);
    });
  });

  it(`handles entered domain with subdomain correctly`, () => {
    cy.visit(`/keychains/123`);
    cy.contains(`Create key`).click();
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
    cy.contains(`Create key`).click();
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
    cy.contains(`Create key`).click();
    cy.contains(`Grant access to a specific website`).click();
    cy.testId(`keycreator-next-step`).click();
    cy.testId(`key-address`).type(`123.146.189.123`);
    cy.testId(`incorrect-ip-hint`).should(`exist`);
  });

  it(`ignores scheme and path if entered by user`, () => {
    cy.visit(`/keychains/123`);
    cy.contains(`Create key`).click();
    cy.contains(`Grant access to a specific website`).click();
    cy.testId(`keycreator-next-step`).click();
    cy.testId(`key-address`).type(`https://radsite.com/with/some-path`); // <-- 👋
    cy.testId(`keycreator-next-step`).should(`not.be.disabled`);

    cy.intercept(`/pairql/dashboard/SaveKey`, (req) => {
      req.alias = `saveKey`;
      req.reply({ success: true });
    });

    cy.testId(`modal-primary-btn`).click();
    cy.wait(`@saveKey`).its(`request.body.key.domain`).should(`equal`, `radsite.com`);
  });

  it(`prevents proceeding and gives useful hint when address invalid`, () => {
    cy.visit(`/keychains/123`);
    cy.contains(`Create key`).click();
    cy.contains(`Grant access to a specific website`).click();
    cy.testId(`keycreator-next-step`).click();
    cy.testId(`key-address`).type(`foo`);
    cy.testId(`keycreator-next-step`).should(`be.disabled`);
  });
});
