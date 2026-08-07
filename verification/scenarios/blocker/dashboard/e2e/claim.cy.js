/// <reference types="cypress" />

// Intent-level claim: assign the pending blocker device to a NEW child through the real
// dashboard claim flow and reach the connected/done screen. Route-based asserts, no copy.
// Exact-copy and component coverage lives in the dashboard's own unit/cypress suites.

const code = Cypress.env(`CLAIM_CODE`);
const adminId = Cypress.env(`ADMIN_ID`);
const adminToken = Cypress.env(`ADMIN_TOKEN`);
const childName = Cypress.env(`CHILD_NAME`) || `Blocker Verification Child`;

function seedAuth(win) {
  win.localStorage.setItem(`admin_id`, adminId);
  win.localStorage.setItem(`admin_token`, adminToken);
  win.localStorage.removeItem(`dev_logged_out`);
}

describe(`Gertrude Blocker device claim`, () => {
  it(`claims the pending device to a new child and reaches the connected screen`, () => {
    cy.visit(`/claim-blocker-device/${code}/claim`, { onBeforeLoad: seedAuth });

    cy.get(`form`); // wait past <Loading/> for the claim form

    // assign to a NEW child. when the parent already has children the picker is a
    // Headless UI listbox defaulting to an existing child (pick "Add someone new");
    // with no children the name input is shown directly.
    cy.get(`body`).then(($body) => {
      if ($body.find(`[data-test=child-name-input]`).length) {
        cy.get(`[data-test=child-name-input]`).type(childName);
      } else {
        cy.get(`button[aria-haspopup="listbox"]`).click();
        cy.contains(`[role="option"]`, `Add someone new`).click();
        cy.get(`input[placeholder="Enter name"]`).type(childName);
      }
    });

    cy.get(`form button[type=submit]`).should(`not.be.disabled`).click();

    cy.url().should(`include`, `/claim-blocker-device/${code}/done`); // persisted + advanced
    cy.contains(/connected/i);
  });
});
