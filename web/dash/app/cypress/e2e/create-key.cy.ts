/// <reference types="cypress" />

describe(`create key flow`, () => {
  beforeEach(() => {
    cy.simulateLoggedIn();
    cy.viewport(1024, 875);
    cy.interceptPql(`SaveKey`, { success: true });
    cy.interceptPql(`GetIdentifiedApps`, [
      {
        id: `app-123`,
        name: `Brave`,
        slug: `brave`,
        launchable: true,
        bundleIds: [],
      },
    ]);
    cy.interceptPql(`GetAdminKeychain`, {
      summary: {
        id: `123`,
        name: `Betsy's Keychain`,
        authorId: `admin-123`,
        isPublic: false,
        numKeys: 0,
      },
      keys: [],
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

    // server should send back keychain with saved key
    cy.interceptPql(`GetAdminKeychain`, {
      summary: {
        id: `123`,
        name: `Betsy's Keychain`,
        authorId: `admin-123`,
        isPublic: false,
        numKeys: 1,
      },
      keys: [
        {
          id: `key-id`,
          keychainId: `keychain-id`,
          key: { type: `domain`, domain: `foo.com`, scope: { type: `webBrowsers` } },
        },
      ],
    });

    cy.testId(`modal-primary-btn`).click();
    cy.testId(`modal-primary-btn`).should(`not.exist`); // modal dismissed
    cy.contains(`Save keychain`).should(`be.disabled`); // keychain not dirty
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

    cy.interceptPql(`SaveKey`, { success: true });

    cy.testId(`modal-primary-btn`).click();
    cy.wait(`@SaveKey`).its(`request.body.key.domain`).should(`equal`, `radsite.com`);
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
