/// <reference types="cypress" />

import type { Device } from '@dash/types';

describe(`computers`, () => {
  const silvery: Device = {
    id: `device-1`,
    modelTitle: `16" Macbook Pro (2023)`,
    name: `Silvery`,
    modelFamily: `macBookPro`,
    modelIdentifier: `Mac14,10`,
    appVersion: `2.0.12`,
    users: [{ name: `Little Jimmy`, id: `user-1`, isOnline: true }],
    serialNumber: `C02Z12345678`,
    releaseChannel: `stable`,
  };

  it(`editing computer`, () => {
    cy.interceptPql(`GetDevices`, [silvery]);
    cy.interceptPql(`GetDevice`, silvery);
    cy.interceptPql(`SaveDevice`, { success: true });
    cy.interceptPql(`LatestAppVersions`, {
      stable: `2.0.12`,
      beta: `2.1.7`,
      canary: `2.2.3`,
    });

    cy.simulateLoggedIn();
    cy.visit(`/computers`);
    cy.contains(`Silvery`);
    cy.contains(`Edit`).click();
    cy.contains(`Up to date`); // <- should be up to date initially
    cy.testId(`release-channel-select`).within(() => {
      cy.get(`button`).click();
    });
    cy.contains(`Beta`).click();
    cy.contains(`Updates available`); // <- updates should be available after switching to beta
    cy.testId(`computer-name-input`).clear().type(`Theodore`);
    cy.contains(`Save`).click();
  });
});
