/// <reference types="cypress" />

describe(`blocker connect claim flow`, () => {
  const claimData = {
    children: [
      { id: `child-1`, name: `Emma` },
      { id: `child-2`, name: `Luke` },
    ],
    modelName: `iPhone 15 Pro`,
    deviceType: `iPhone`,
    iosVersion: `18.2`,
  };

  beforeEach(() => {
    cy.simulateLoggedIn();
  });

  describe(`claim route`, () => {
    it(`shows child picker when parent has children`, () => {
      cy.interceptPql(`GetBlockerClaimData`, claimData);

      cy.visit(`/claim-blocker-device/687084/claim`);

      cy.wait(`@GetBlockerClaimData`);
      cy.contains(`iPhone 15 Pro`); // device context banner
      cy.contains(`iOS 18.2`);
      cy.contains(`Who is the user of this iPhone?`);
      cy.contains(`Continue`);
    });

    it(`shows name input directly when parent has no children`, () => {
      cy.interceptPql(`GetBlockerClaimData`, { ...claimData, children: [] });

      cy.visit(`/claim-blocker-device/687084/claim`);

      cy.wait(`@GetBlockerClaimData`);
      cy.get(`[data-test="child-name-input"]`).should(`exist`);
      cy.contains(`Add Device`);
    });
  });

  describe(`happy path`, () => {
    it(`claims to an existing child and lands on the connected screen`, () => {
      cy.interceptPql(`GetBlockerClaimData`, claimData);
      cy.interceptPql(`ClaimBlockerDevice`, {
        childName: `Emma`,
        childId: `child-1`,
        deviceId: `device-1`,
        modelName: `iPhone 15 Pro`,
        iosVersion: `18.2`,
        code: 687084,
      });

      cy.visit(`/claim-blocker-device/687084/claim`);
      cy.wait(`@GetBlockerClaimData`);

      cy.contains(`Continue`).click(); // first child (Emma) is pre-selected
      cy.wait(`@ClaimBlockerDevice`);

      cy.location(`pathname`).should(`eq`, `/claim-blocker-device/687084/done`);
      cy.contains(`iPhone connected`).should(`be.visible`);
      cy.contains(`Gertrude Blocker is now installed on Emma`).should(`be.visible`);

      // primary button deep-links into the device settings page, not the dashboard root
      cy.interceptPql(`GetIOSDevice_v2`, {
        childName: `Emma`,
        deviceType: `iPhone`,
        osVersion: `18.2`,
        musicConnected: false,
      });
      cy.contains(`iPhone settings`).click();
      cy.location(`pathname`).should(`eq`, `/children/child-1/ios-devices/device-1`);
    });
  });

  describe(`done route`, () => {
    it(`redirects to the claim step when reached without nav state`, () => {
      cy.interceptPql(`GetBlockerClaimData`, claimData);

      cy.visit(`/claim-blocker-device/687084/done`);

      cy.location(`pathname`).should(`eq`, `/claim-blocker-device/687084/claim`);
    });
  });

  describe(`resume`, () => {
    it(`auto-forwards an already-claimed code straight to the connected screen`, () => {
      cy.interceptPql(`GetBlockerClaimData`, {
        ...claimData,
        children: [],
        resumeStep: {
          case: `done`,
          childName: `Luke`,
          childId: `child-2`,
          deviceId: `device-2`,
        },
      });

      cy.visit(`/claim-blocker-device/687084/claim`);
      cy.wait(`@GetBlockerClaimData`);

      cy.location(`pathname`).should(`eq`, `/claim-blocker-device/687084/done`);
      cy.contains(`Gertrude Blocker is now installed on Luke`).should(`be.visible`);
    });
  });
});
