/// <reference types="cypress" />

// Intent-level verification: a connected device's claim route resume-redirects to the
// done/connected screen (a still-pending one stays on /claim). Route-based, copy-free.

const code = Cypress.env(`CLAIM_CODE`);
const adminId = Cypress.env(`ADMIN_ID`);
const adminToken = Cypress.env(`ADMIN_TOKEN`);

function seedAuth(win) {
  win.localStorage.setItem(`admin_id`, adminId);
  win.localStorage.setItem(`admin_token`, adminToken);
}

describe(`podcasts device dashboard verification`, () => {
  it(`shows the claimed device as connected`, () => {
    cy.visit(`/claim-podcasts-device/${code}/claim`, { onBeforeLoad: seedAuth });

    cy.url().should(`include`, `/claim-podcasts-device/${code}/done`); // resume -> connected
    cy.contains(/connected/i);
  });
});
