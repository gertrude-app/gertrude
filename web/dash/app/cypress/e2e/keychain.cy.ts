/// <reference types="cypress" />
import type { AdminKeychain } from '@dash/types';
import * as mock from '../../src/reducers/__tests__/mocks';
import { betsy } from '../fixtures/helpers';

describe(`create keychain`, () => {
  beforeEach(() => {
    cy.simulateLoggedIn();
    cy.interceptPql(`GetIdentifiedApps`, []);
    cy.interceptPql(`SaveKeychain`, { success: true });
    cy.interceptPql(`DeleteEntity_v2`, { success: true });
    cy.interceptPql(`GetChildren`, [mock.child()]);
    cy.interceptPql(`GetChild`, mock.child());
  });

  it(`doesn't allow selection of recently deleted keychains`, () => {
    const existing: AdminKeychain = {
      summary: mock.keychainSummary({ name: `Existing`, parentId: betsy.id }),
      keys: [],
      children: [],
    };

    cy.interceptPql(`GetAdminKeychains`, {
      keychains: [existing],
      children: [],
      hasAnyMacComputers: true,
    });
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
    cy.contains(`For Mac Computers`).click();
    cy.contains(`Manage filtering`).click();
    cy.contains(`Add keychain`).click();
    cy.contains(`Existing`).should(`not.exist`);
  });

  it(`(the keychain picker) shows empty state when child already has all personal keychains`, () => {
    const existing: AdminKeychain = {
      summary: mock.keychainSummary({ name: `Test keychain`, parentId: betsy.id }),
      keys: [],
      children: [],
    };

    cy.interceptPql(`GetAdminKeychains`, {
      keychains: [existing],
      children: [],
      hasAnyMacComputers: true,
    });
    cy.interceptPql(`GetSelectableKeychains`, {
      own: [existing.summary],
      public: [],
    });
    cy.interceptPql(`GetChild`, mock.child({ keychains: [existing.summary] }));

    cy.visit(`/keychains`);
    cy.contains(`Test keychain`);
    cy.sidebarClick(`Children`);
    cy.testId(`edit-user`).click();
    cy.contains(`For Mac Computers`).click();
    cy.contains(`Manage filtering`).click();
    cy.contains(`Test keychain`);
    cy.contains(`Add keychain`).click();
  });

  describe(`no keychains to start`, () => {
    beforeEach(() => {
      // parent starts with no keychains
      cy.interceptPql(`GetAdminKeychains`, {
        keychains: [],
        children: [],
        hasAnyMacComputers: true,
      });
      // and no prior selectable keychains
      cy.interceptPql(`GetSelectableKeychains`, { own: [], public: [] });
    });

    it(`(the keychain picker) shows empty state when parent has no personal keychains to assign`, () => {
      cy.visit(`/children`);
      cy.testId(`edit-user`).click();
      cy.contains(`For Mac Computers`).click();
      cy.contains(`Manage filtering`).click();
      cy.contains(`Add keychain`).click();
      cy.contains(`Looks like you don't have any keychains`);
    });
  });
});
