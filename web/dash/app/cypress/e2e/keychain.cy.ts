/// <reference types="cypress" />
import type { AdminKeychain } from '@dash/types';
import { betsy } from '../fixtures/helpers';
import * as mock from '../../src/reducers/__tests__/mocks';

describe(`create keychain`, () => {
  beforeEach(() => {
    cy.simulateLoggedIn();
    cy.interceptPql(`GetIdentifiedApps`, []);
    cy.interceptPql(`SaveKeychain`, { success: true });
    cy.interceptPql(`DeleteEntity`, { success: true });
    cy.interceptPql(`GetUsers`, [mock.user()]);
    cy.interceptPql(`GetUser`, mock.user());
  });

  it(`doesn't allow selection of recently deleted keychains`, () => {
    const existing: AdminKeychain = {
      summary: mock.keychainSummary({ name: `Existing`, authorId: betsy.id }),
      keys: [],
    };

    cy.interceptPql(`GetAdminKeychains`, [existing]);
    cy.interceptPql(`GetSelectableKeychains`, { own: [], public: [] });

    cy.visit(`/keychains`);
    cy.contains(`Existing`)
      .parents(`[data-test=keychain-card]`)
      .within(() => {
        cy.testId(`remove-keychain`).click();
      });
    cy.testId(`modal-primary-btn`).click();
    cy.sidebarClick(`Children`);
    cy.testId(`edit-user`).click();
    cy.contains(`Add keychain`).click();
    cy.contains(`Existing`).should(`not.exist`);
  });

  it(`(the keychain picker) shows empty state when user already has all personal keychains`, () => {
    const existing: AdminKeychain = {
      summary: mock.keychainSummary({ name: `Test keychain`, authorId: betsy.id }),
      keys: [],
    };

    cy.interceptPql(`GetAdminKeychains`, [existing]);
    cy.interceptPql(`GetSelectableKeychains`, {
      own: [existing.summary],
      public: [],
    });
    cy.interceptPql(`GetUser`, mock.user({ keychains: [existing.summary] }));

    cy.visit(`/keychains`);
    cy.contains(`Test keychain`);
    cy.sidebarClick(`Children`);
    cy.testId(`edit-user`).click();
    cy.contains(`Test keychain`);
    cy.contains(`Add keychain`).click();
  });

  describe(`no keychains to start`, () => {
    beforeEach(() => {
      // admin starts with no keychains
      cy.interceptPql(`GetAdminKeychains`, []);
      // and no prior selectable keychains
      cy.interceptPql(`GetSelectableKeychains`, { own: [], public: [] });
    });

    it(`(the keychain picker) shows empty state when admin has no personal keychains to assign`, () => {
      cy.visit(`/users`);
      cy.testId(`edit-user`).click();
      cy.contains(`Add keychain`).click();
      cy.contains(`No personal keychains`);
    });
  });
});
