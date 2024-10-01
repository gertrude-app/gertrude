/// <reference types="cypress" />
import * as mock from '../../src/reducers/__tests__/mocks';

describe(`children screen`, () => {
  beforeEach(() => {
    cy.simulateLoggedIn();
    cy.interceptPql(`SaveUser`, { success: true });
    cy.interceptPql(`GetUsers`, [mock.user({ id: `user-123` })]);
    cy.interceptPql(`DeleteEntity`, { success: true });
  });

  describe(`new child creation`, () => {
    it(`creating and updating child`, () => {
      cy.visit(`/children/new`);
      cy.testId(`user-name`).type(`Bo`);

      // simulate freshly saved user from server
      cy.intercept(
        `/pairql/dashboard/GetUser`,
        mock.user({ name: `Bo`, id: `user-123` }),
      );

      cy.contains(`Save child`).click();
      cy.wait(`@SaveUser`);

      cy.testId(`page-heading`).should(`have.text`, `Child settings`);
      cy.contains(`Save child`).should(`be.disabled`);

      cy.testId(`user-name`).type(`az`);

      cy.contains(`Save child`).should(`be.enabled`);
    });

    it(`redirects to new uuid path & doesn't list unsaved new child`, () => {
      cy.visit(`/children/new`);

      // redirects to /children/<new-user-id>
      cy.location(`pathname`).should(`not.eq`, `/children/new`);
      cy.contains(`Add a child`);

      // don't show the empty new user in the list
      cy.sidebarClick(`Children`);
      cy.testId(`user-card`).should(`have.length`, 1);
    });
  });

  describe(`child deletion`, () => {
    it(`redirects to /children path`, () => {
      cy.interceptPql(`GetUser`, mock.user({ id: `user-123` }));
      cy.visit(`/children/user-123`);

      cy.contains(`Delete child`).click();
      cy.testId(`modal-primary-btn`).click();

      // redirects to /children
      cy.location(`pathname`).should(`eq`, `/children`);
    });
  });
});
