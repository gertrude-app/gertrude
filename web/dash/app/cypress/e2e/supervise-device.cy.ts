/// <reference types="cypress" />

describe(`supervise device claim flow`, () => {
  const claimParams = `claimPendingSupervision=123456&modelName=iPhone+15+Pro&iosVersion=18.2&redirect=/supervise-device/123456/claim`;

  describe(`device context banner on auth pages`, () => {
    it(`shows banner on signup page with claim params`, () => {
      cy.visit(`/signup?${claimParams}`);
      cy.contains(`iPhone 15 Pro`);
      cy.contains(`iOS 18.2`);
    });

    it(`shows banner on login page with claim params`, () => {
      cy.visit(`/login?${claimParams}`);
      cy.contains(`iPhone 15 Pro`);
      cy.contains(`iOS 18.2`);
    });

    it(`preserves params when navigating from signup to login`, () => {
      cy.visit(`/signup?${claimParams}`);
      cy.contains(`Login`).click();
      cy.location(`pathname`).should(`eq`, `/login`);
      cy.location(`search`).should(`include`, `claimPendingSupervision=123456`);
      cy.location(`search`).should(`include`, `modelName=iPhone`);
      cy.contains(`iPhone 15 Pro`);
    });

    it(`preserves params when navigating from login to signup`, () => {
      cy.visit(`/login?${claimParams}`);
      cy.contains(`signup`).click();
      cy.location(`pathname`).should(`eq`, `/signup`);
      cy.location(`search`).should(`include`, `claimPendingSupervision=123456`);
      cy.location(`search`).should(`include`, `modelName=iPhone`);
      cy.contains(`iPhone 15 Pro`);
    });
  });

  describe(`claim route`, () => {
    beforeEach(() => {
      cy.simulateLoggedIn();
    });

    it(`shows child picker when parent has children`, () => {
      cy.interceptPql(`GetIOSDeviceClaimData`, {
        children: [
          { id: `child-1`, name: `Emma` },
          { id: `child-2`, name: `Luke` },
        ],
        modelName: `iPhone 15 Pro`,
        deviceType: `iPhone`,
        iosVersion: `18.2`,
      });

      cy.visit(`/supervise-device/123456/claim`);

      cy.wait(`@GetIOSDeviceClaimData`);
      cy.contains(`Who is the user of this iPhone?`);
      cy.contains(`Continue`);
    });

    it(`shows name input directly when parent has no children`, () => {
      cy.interceptPql(`GetIOSDeviceClaimData`, {
        children: [],
        modelName: `iPhone 15 Pro`,
        deviceType: `iPhone`,
        iosVersion: `18.2`,
      });

      cy.visit(`/supervise-device/123456/claim`);

      cy.wait(`@GetIOSDeviceClaimData`);
      cy.get(`[data-test="child-name-input"]`).should(`exist`);
    });

    it(`redirects to login if not authenticated`, () => {
      localStorage.clear();
      cy.visit(`/supervise-device/123456/claim`);
      cy.location(`pathname`).should(`eq`, `/login`);
    });
  });
});
