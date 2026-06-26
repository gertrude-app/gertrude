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

  describe(`payment gating (regression: unpaid account reached download step)`, () => {
    const unpaidStatus = {
      deviceId: `11300000-0000-0000-0000-000000000000`,
      childId: `a9aa0000-0000-0000-0000-000000000000`,
      childName: `Jacob`,
      modelName: `iPhone 12`,
      deviceType: `iPhone`,
      iosVersion: `26.0`,
      supervisionStatus: `awaitingSupervision` as const,
      requiresPayment: true,
      paymentAction: { case: `startCheckout`, tier: `light` } as const,
    };

    beforeEach(() => {
      cy.simulateLoggedIn();
      cy.interceptPql(`StartCheckoutSession`, { url: `https://stripe.test/checkout` });
    });

    // each protected step must be gated, not just the one the customer hit
    for (const step of [`download-helper`, `launch-helper`, `supervise`]) {
      it(`gates an unpaid account away from /${step} to the payment screen`, () => {
        cy.interceptPql(`GetIOSDeviceSupervisionStatus`, unpaidStatus);

        cy.visit(`/supervise-device/326590/${step}`);
        cy.wait(`@GetIOSDeviceSupervisionStatus`);

        // must NOT silently present a working-looking helper download UI
        cy.contains(`Download the Supervision Helper App`).should(`not.exist`);
        cy.contains(`Launch the Supervision Helper App`).should(`not.exist`);

        // must redirect to payment and clearly surface "subscription required"
        cy.location(`pathname`).should(`eq`, `/supervise-device/326590/payment`);
        cy.contains(`Subscribe to Continue`).should(`be.visible`);
        cy.contains(`Gertrude subscription`).should(`be.visible`);
        cy.contains(`Subscribe`).should(`be.visible`);
      });
    }

    it(`never fires the silently-swallowed download request for an unpaid account`, () => {
      cy.interceptPql(`GetIOSDeviceSupervisionStatus`, unpaidStatus);
      cy.intercept(`GET`, `**/download-supervision-app/**`, cy.spy().as(`dlReq`));

      cy.visit(`/supervise-device/326590/download-helper`);
      cy.wait(`@GetIOSDeviceSupervisionStatus`);

      // surfaced as "subscription required -> here's how", not a dead button
      cy.contains(`Subscribe to Continue`).should(`be.visible`);
      cy.get(`@dlReq`).should(`not.have.been.called`);
    });

    it(`lets a paid account reach the download step`, () => {
      cy.interceptPql(`GetIOSDeviceSupervisionStatus`, {
        ...unpaidStatus,
        requiresPayment: false,
      });

      cy.visit(`/supervise-device/326590/download-helper`);
      cy.wait(`@GetIOSDeviceSupervisionStatus`);

      cy.location(`pathname`).should(`eq`, `/supervise-device/326590/download-helper`);
      cy.contains(`Download the Supervision Helper App`).should(`be.visible`);
    });

    it(`does not bounce a supervised (paid-then-lapsed) account away from done`, () => {
      cy.interceptPql(`GetIOSDeviceSupervisionStatus`, {
        ...unpaidStatus,
        supervisionStatus: `supervised`,
        requiresPayment: true,
      });

      cy.visit(`/supervise-device/326590/done`);
      cy.wait(`@GetIOSDeviceSupervisionStatus`);

      cy.location(`pathname`).should(`eq`, `/supervise-device/326590/done`);
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
  });

  describe(`done screen`, () => {
    beforeEach(() => {
      cy.simulateLoggedIn();
    });

    // regression: button linked to /ios-devices/:id, which redirects to /devices
    it(`Manage button deep-links to the device settings page`, () => {
      cy.interceptPql(`GetIOSDeviceSupervisionStatus`, {
        deviceId: `11300000-0000-0000-0000-000000000000`,
        childId: `a9aa0000-0000-0000-0000-000000000000`,
        childName: `Jacob`,
        modelName: `iPhone 12`,
        deviceType: `iPhone`,
        iosVersion: `26.0`,
        supervisionStatus: `supervised`,
        requiresPayment: false,
        paymentAction: { case: `startCheckout`, tier: `light` },
      });
      cy.interceptPql(`GetIOSDevice_v2`, {
        childName: `Jacob`,
        deviceType: `iPhone`,
        osVersion: `26.0`,
        musicConnected: false,
      });

      cy.visit(`/supervise-device/326590/done`);
      cy.wait(`@GetIOSDeviceSupervisionStatus`);

      cy.contains(`Manage iPhone`).click();
      cy.location(`pathname`).should(
        `eq`,
        `/children/a9aa0000-0000-0000-0000-000000000000/ios-devices/11300000-0000-0000-0000-000000000000`,
      );
    });
  });
});
