/// <reference types="cypress" />

describe(`music claim flow`, () => {
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
      cy.interceptPql(`GetMusicClaimData`, claimData);

      cy.visit(`/claim-music-device/687084/claim`);

      cy.wait(`@GetMusicClaimData`);
      cy.contains(`iPhone 15 Pro`); // device context banner
      cy.contains(`iOS 18.2`);
      cy.contains(`Who is the user of this iPhone?`);
      cy.contains(`Continue`);
    });

    it(`shows name input directly when parent has no children`, () => {
      cy.interceptPql(`GetMusicClaimData`, { ...claimData, children: [] });

      cy.visit(`/claim-music-device/687084/claim`);

      cy.wait(`@GetMusicClaimData`);
      cy.get(`[data-test="child-name-input"]`).should(`exist`);
      cy.contains(`Add Device`);
    });
  });

  describe(`happy path`, () => {
    it(`claims to an existing child and lands on a neutral connected screen`, () => {
      cy.interceptPql(`GetMusicClaimData`, claimData);
      cy.interceptPql(`ClaimMusicDevice`, {
        childName: `Emma`,
        childId: `child-1`,
        deviceId: `device-1`,
        modelName: `iPhone 15 Pro`,
        iosVersion: `18.2`,
        code: 687084,
      });

      cy.visit(`/claim-music-device/687084/claim`);
      cy.wait(`@GetMusicClaimData`);

      cy.contains(`Continue`).click(); // first child (Emma) is pre-selected
      cy.wait(`@ClaimMusicDevice`);

      cy.location(`pathname`).should(`eq`, `/claim-music-device/687084/done`);
      cy.contains(`iPhone connected`).should(`be.visible`);
      cy.contains(`Gertrude Music is now connected on Emma`).should(`be.visible`);
    });

    it(`completes without ever routing through a payment step`, () => {
      cy.interceptPql(`GetMusicClaimData`, claimData);
      cy.interceptPql(`ClaimMusicDevice`, {
        childName: `Emma`,
        childId: `child-1`,
        deviceId: `device-1`,
        modelName: `iPhone 15 Pro`,
        iosVersion: `18.2`,
        code: 687084,
      });
      const visited: string[] = [];
      cy.on(`url:changed`, (url: string) => visited.push(url));

      cy.visit(`/claim-music-device/687084/claim`);
      cy.wait(`@GetMusicClaimData`);
      cy.contains(`Continue`).click();
      cy.wait(`@ClaimMusicDevice`);

      cy.location(`pathname`).should(`eq`, `/claim-music-device/687084/done`);
      cy.wrap(visited).should((urls) => {
        expect(urls.join(` `)).not.to.contain(`/payment`);
      });
    });
  });

  describe(`done screen`, () => {
    const doneClaimData = {
      ...claimData,
      children: [],
      resumeStep: {
        case: `done` as const,
        childName: `Luke`,
        childId: `child-2`,
        deviceId: `device-2`,
      },
    };

    it(`shows no plan, price, subscription, or billing language`, () => {
      cy.interceptPql(`GetMusicClaimData`, doneClaimData);

      cy.visit(`/claim-music-device/687084/claim`);
      cy.location(`pathname`).should(`eq`, `/claim-music-device/687084/done`);

      cy.get(`body`)
        .invoke(`text`)
        .should((text: string) => {
          for (const banned of [
            `subscription`,
            `Medium`,
            `Full`,
            `upgrade`,
            `plan`,
            `trial`,
            `billing`,
            `checkout`,
            `$`,
          ]) {
            expect(text.toLowerCase()).not.to.contain(banned.toLowerCase());
          }
        });
    });

    it(`returns to the dashboard root rather than the device page plan gate`, () => {
      cy.interceptPql(`GetMusicClaimData`, doneClaimData);
      cy.interceptPql(`DashboardWidgets_v3`, {
        children: [],
        unlockRequests: [],
        childActivitySummaries: [],
        recentScreenshots: [],
        numParentNotifications: 0,
        pendingIOSDevices: [],
      });

      cy.visit(`/claim-music-device/687084/claim`);
      cy.location(`pathname`).should(`eq`, `/claim-music-device/687084/done`);

      cy.contains(`Return to dashboard`).click();
      cy.location(`pathname`).should(`eq`, `/`); // never /children/:id/ios-devices/:id
    });

    it(`redirects to the claim step when reached without nav state`, () => {
      cy.interceptPql(`GetMusicClaimData`, claimData);

      cy.visit(`/claim-music-device/687084/done`);

      cy.location(`pathname`).should(`eq`, `/claim-music-device/687084/claim`);
    });
  });

  describe(`resume`, () => {
    it(`auto-forwards an already-claimed code straight to the connected screen`, () => {
      cy.interceptPql(`GetMusicClaimData`, {
        ...claimData,
        children: [],
        resumeStep: {
          case: `done`,
          childName: `Luke`,
          childId: `child-2`,
          deviceId: `device-2`,
        },
      });

      cy.visit(`/claim-music-device/687084/claim`);
      cy.wait(`@GetMusicClaimData`);

      cy.location(`pathname`).should(`eq`, `/claim-music-device/687084/done`);
      cy.contains(`Gertrude Music is now connected on Luke`).should(`be.visible`);
    });
  });

  describe(`retired payment route`, () => {
    it(`redirects the stale payment url to the claim step instead of a plan gate`, () => {
      cy.interceptPql(`GetMusicClaimData`, claimData);

      cy.visit(`/claim-music-device/687084/payment`);

      cy.location(`pathname`).should(`eq`, `/claim-music-device/687084/claim`);
      cy.contains(`Who is the user of this iPhone?`);
    });
  });
});
