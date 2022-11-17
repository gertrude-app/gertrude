/// <reference types="cypress" />
// https://on.cypress.io/custom-commands
// https://github.com/cypress-io/cypress-example-todomvc#cypress-intellisense

Cypress.Commands.add(`simulateLoggedIn`, () => {
  localStorage.setItem(`admin_id`, `be000000-0000-0000-0000-000000000000`);
  localStorage.setItem(`admin_token`, `be000000-0000-0000-0000-000000000000`);
});

Cypress.Commands.add(`testId`, (selector, ...args) => {
  return cy.get(`[data-test=${selector}]`, ...args);
});
