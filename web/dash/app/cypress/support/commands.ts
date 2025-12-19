/// <reference types="cypress" />
import { betsy } from '../fixtures/helpers';
import { forcePqlErr, interceptPql } from './intercept';

// https://on.cypress.io/custom-commands
// https://github.com/cypress-io/cypress-example-todomvc#cypress-intellisense

Cypress.Commands.add(`simulateLoggedIn`, () => {
  localStorage.setItem(`admin_id`, betsy.id);
  localStorage.setItem(`admin_token`, betsy.token);
});

Cypress.Commands.add(`testId`, (selector, ...args) => {
  return cy.get(`[data-test=${selector}]`, ...args);
});

Cypress.Commands.add(`sidebarClick`, (link) => {
  cy.testId(`sidebar-nav`).within(() => {
    cy.contains(link).click();
  });
});

Cypress.Commands.add(`interceptPql`, interceptPql);
Cypress.Commands.add(`forcePqlErr`, forcePqlErr);
