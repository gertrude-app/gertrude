/// <reference types="cypress" />
describe(`Smoke test`, () => {
  const namespace = Cypress.env(`SMOKE_TEST_TESTMAIL_NAMESPACE`);
  const email = `${namespace}.smoke-test-${Date.now()}@inbox.testmail.app`;
  const password = `_pw_${Date.now()}`;

  it(`verify download dmg is reachable`, () => {
    cy.request({
      method: `HEAD`,
      url: `https://gertrude.nyc3.digitaloceanspaces.com/releases/Gertrude.dmg`,
    })
      .its(`status`)
      .should(`eq`, 200);
  });

  it(`critical flows`, () => {
    // signup
    cy.visit(`/signup`);
    cy.get(`input[name=email]`).type(email);
    cy.get(`input[name=password]`).type(`${password}{enter}`);
    cy.contains(`Verification email sent`);
    cy.wait(Cypress.env(`CI`) ? 60000 : 7500);

    // verify email
    cy.request({ url: Cypress.env(`SMOKE_TEST_EMAIL_INBOX_URL`) }).then((response) => {
      const body = JSON.stringify(response.body);
      if (!body.includes(email)) {
        throw new Error(`Expected to find email ${email} in ${body}`);
      }
      const match = body.match(/"([^" ]+verify-signup-email[^" ]+)"/);
      if (!match) {
        throw new Error(`Expected to find verify link in ${body}`);
      }
      cy.wrap(match[1]).as(`verifyLink`);
    });
    cy.get(`@verifyLink`).then((verifyLink) => {
      cy.visit({ url: verifyLink as any });
    });
    cy.contains(`I’m a parent`).click();
    cy.contains(`Welcome to the parent website!`);

    // log out, then back in w/ email/pass
    cy.contains(`Log out`).click();
    cy.visit(`/`);
    cy.location(`pathname`).should(`eq`, `/login`);
    cy.get(`input[name=email]`).type(email);
    cy.get(`input[name=password]`).type(`${password}{enter}`);
    cy.location(`pathname`).should(`eq`, `/`);

    // create a child
    cy.contains(`Add a child`).click();
    cy.get(`[data-test=user-name]`).type(`Franny`);
    cy.contains(`Save child`).click();

    // get the connection code
    cy.contains(`Get connection code`).click();
    cy.get(`[data-test=connection-code]`).invoke(`text`).as(`connectionCode`);

    // simulate that they installed the app and connected successfully
    cy.get(`@connectionCode`).then((connectionCode) => {
      cy.log(`connectionCode`, connectionCode);
      cy.request({
        method: `POST`,
        url: `${Cypress.env(`SMOKE_TEST_API_URL`)}/pairql/macos-app/ConnectUser`,
        headers: { 'Content-Type': `application/json` },
        body: {
          verificationCode: Number(connectionCode),
          appVersion: `2.1.2`,
          modelIdentifier: `MacBookPro16,1`,
          username: `franny`,
          fullUsername: `Franny`,
          numericId: 502,
          serialNumber: `C02ZL0J${Math.random()}`,
        },
      })
        .its(`status`)
        .should(`eq`, 200);
    });

    // dismiss connection modal
    cy.get(`[data-test="modal-primary-btn"]`).click();
    cy.visit(`/children`);
    cy.contains(`MacBook Pro`);

    // edit the user
    cy.get(`[data-test="edit-user"]`).click();
    cy.get(`[data-test=user-name]`).clear().type(`Franny (edited)`);
    cy.contains(`Save child`).click();
    cy.contains(`Child saved`);
  });
});
