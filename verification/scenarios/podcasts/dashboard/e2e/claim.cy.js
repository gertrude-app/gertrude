/// <reference types="cypress" />

// Intent-level claim flow: move through the phases (load -> assign child -> submit ->
// reach the connected route) and assert on routes/structural hooks, not dashboard copy.
// Exact-copy and component coverage lives in the dashboard's own unit/cypress suites.

const code = Cypress.env(`CLAIM_CODE`);
const adminId = Cypress.env(`ADMIN_ID`);
const adminToken = Cypress.env(`ADMIN_TOKEN`);
const childName = Cypress.env(`CHILD_NAME`) || `Verification Child`;

function seedAuth(win) {
  win.localStorage.setItem(`admin_id`, adminId);
  win.localStorage.setItem(`admin_token`, adminToken);
}

describe(`podcasts device claim`, () => {
  it(`claims the pending device and reaches the connected screen`, () => {
    cy.visit(`/claim-podcasts-device/${code}/claim`, { onBeforeLoad: seedAuth });

    cy.get(`form`); // wait past <Loading/> for the claim form

    // critical action: assign the device to a child. with no children yet a name is
    // required; otherwise an existing child is pre-selected and we just submit.
    cy.get(`body`).then(($body) => {
      if ($body.find(`[data-test=child-name-input]`).length) {
        cy.get(`[data-test=child-name-input]`).type(childName);
      }
    });
    cy.get(`form button[type=submit]`).should(`not.be.disabled`).click();

    cy.url().should(`include`, `/claim-podcasts-device/${code}/done`); // claim persisted + advanced
    cy.contains(/connected/i);
  });
});
