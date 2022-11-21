/// <reference types="cypress" />
import ListUsers from '../fixtures/ListUsers.json';

describe(`user screen`, () => {
  beforeEach(() => {
    cy.simulateLoggedIn();
    cy.intercept(`/graphql/dashboard`, (req) => {
      switch (req.body.operationName) {
        case `ListUsers`:
          req.alias = `listUsers`;
          req.reply(ListUsers);
          break;
        case `CreateUser`:
          req.alias = `createUser`;
          req.reply({ data: { user: { id: `123` } } });
          break;
        case `UpdateUser`:
          req.alias = `updateUser`;
          req.reply({ data: { user: { id: `123` } } });
          break;
      }
    });
  });

  describe(`new user creation`, () => {
    it(`creating and updating user`, () => {
      cy.visit(`/users/new`);
      cy.testId(`user-name`).type(`Bo`);

      cy.contains(`Save user`).click();
      cy.wait(`@createUser`);

      cy.testId(`page-heading`).should(`have.text`, `Edit user`);
      cy.contains(`Save user`).should(`be.disabled`);

      cy.testId(`user-name`).type(`az`);
      cy.contains(`Save user`).should(`be.enabled`).click();
      cy.wait(`@updateUser`);

      cy.sidebarClick(`Users`);
      cy.contains(`Boaz`);
      cy.testId(`user-card`).should(`have.length`, 2);
    });

    it(`redirects to new uuid path & doesn't list unsaved new user`, () => {
      cy.visit(`/users/new`);

      // redirects to /users/<new-user-id>
      cy.location(`pathname`).should(`not.eq`, `/users/new`);
      cy.contains(`Create user`);

      // don't show the empty new user in the list
      cy.sidebarClick(`Users`);
      cy.testId(`user-card`).should(`have.length`, 1);
    });
  });
});
