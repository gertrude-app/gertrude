/// <reference types="cypress" />

describe(`create keychain`, () => {
  beforeEach(() => {
    cy.simulateLoggedIn();
  });

  it(`allows selection of brand new keychains`, () => {
    cy.visit(`/keychains`);
    cy.contains(`Create keychain`).click();
    cy.get(`input[name=name]`).type(`New test keychain`);
    cy.contains(`Create keychain`).click();
    cy.visit(`/users`);
    cy.contains(`Edit`).click();
    cy.contains(`Add keychain`).click();
    cy.contains(`New test keychain`);
  });

  it(`doesn't allow selection of recently deleted keychains`, () => {
    cy.visit(`/keychains`);
    cy.contains(`Jimmy's Music Theory`)
      .parents(`[data-test=keychain-card]`)
      .within(() => {
        cy.testId(`remove-keychain`).click();
      });
    cy.testId(`modal-primary-btn`).click();
    cy.visit(`/users`);
    cy.contains(`Edit`).click();
    cy.contains(`Add keychain`).click();
    cy.contains(`Jimmy's Music Theory`).should(`not.exist`);
  });
});
