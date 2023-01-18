/// <reference types="cypress" />
import type { AdminKeychain } from '@dash/types';
import { betsy } from '../fixtures/helpers';
import * as mock from '../../src/redux/__tests__/mocks';

describe(`create keychain`, () => {
  beforeEach(() => {
    cy.simulateLoggedIn();
    cy.intercept(`/pairql/dashboard/GetIdentifiedApps`, []);
    cy.intercept(`/pairql/dashboard/SaveKeychain`, { success: true });
    cy.intercept(`/pairql/dashboard/DeleteEntity`, { success: true });
    cy.intercept(`/pairql/dashboard/GetUsers`, [mock.user()]);
  });

  it(`allows selection of brand new keychains`, () => {
    // admin starts with no keychains
    cy.intercept(`/pairql/dashboard/GetAdminKeychains`, []);
    // and no prior selectable keychains
    cy.intercept(`/pairql/dashboard/GetSelectableKeychains`, { own: [], public: [] });

    cy.visit(`/keychains`);
    cy.contains(`Create keychain`).click();
    cy.get(`input[name=name]`).type(`New test keychain`);
    cy.contains(`Create keychain`).click();
    cy.sidebarClick(`Users`);
    cy.testId(`edit-user`).click();
    cy.contains(`Add keychain`).click();
    cy.contains(`New test keychain`);
  });

  it(`doesn't allow selection of recently deleted keychains`, () => {
    const existing: AdminKeychain = {
      summary: mock.keychainSummary({ name: `Existing`, authorId: betsy.id }),
      keys: [],
    };

    cy.intercept(`/pairql/dashboard/GetAdminKeychains`, [existing]);
    cy.intercept(`/pairql/dashboard/GetSelectableKeychains`, { own: [], public: [] });

    cy.visit(`/keychains`);
    cy.contains(`Existing`)
      .parents(`[data-test=keychain-card]`)
      .within(() => {
        cy.testId(`remove-keychain`).click();
      });
    cy.testId(`modal-primary-btn`).click();
    cy.sidebarClick(`Users`);
    cy.testId(`edit-user`).click();
    cy.contains(`Add keychain`).click();
    cy.contains(`Existing`).should(`not.exist`);
  });
});
