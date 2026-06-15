/// <reference types="cypress" />
import * as mock from '../../src/reducers/__tests__/mocks';

describe(`children screen`, () => {
  beforeEach(() => {
    cy.simulateLoggedIn();
    cy.interceptPql(`SaveUser`, { success: true });
    cy.interceptPql(`GetChildren`, [mock.child({ id: `user-123` })]);
    cy.interceptPql(`DeleteEntity_v2`, { success: true });
  });

  describe(`new child creation`, () => {
    it(`creating and updating child`, () => {
      cy.visit(`/children/new`);
      cy.testId(`user-name`).type(`Bo`);

      // simulate freshly saved user from server
      cy.intercept(
        `/pairql/dashboard/GetChild`,
        mock.child({ name: `Bo`, id: `user-123` }),
      );

      cy.contains(`Save child`).click();
      cy.wait(`@SaveUser`);

      cy.testId(`page-heading`).should(`have.text`, `Child settings`);
      cy.contains(`Save`).should(`not.be.visible`);

      cy.testId(`user-name`).type(`az`);

      cy.contains(`Save`).should(`be.visible`);
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

  describe(`music settings`, () => {
    it(`hides music settings until Gertrude Music is connected`, () => {
      cy.interceptPql(
        `GetChild`,
        mock.child({
          id: `user-123`,
          iosDevices: [
            {
              id: `ios-device-123`,
              modelName: `iPhone 15 Pro`,
              deviceType: `iPhone`,
              iosVersion: `18.2`,
              musicConnected: false,
            },
          ],
        }),
      );
      cy.visit(`/children/user-123`);

      cy.contains(/^Music$/).should(`not.exist`);
    });

    it(`does not show separate music settings once Gertrude Music is connected`, () => {
      cy.interceptPql(
        `GetChild`,
        mock.child({
          id: `user-123`,
          iosDevices: [
            {
              id: `ios-device-123`,
              modelName: `iPhone 15 Pro`,
              deviceType: `iPhone`,
              iosVersion: `18.2`,
              musicConnected: true,
            },
          ],
        }),
      );
      cy.visit(`/children/user-123`);

      cy.contains(/^Music$/).should(`not.exist`);
      cy.contains(`For iPhones and iPads`).should(`exist`);
    });
  });

  describe(`iOS device details`, () => {
    it(`shows Gertrude Music curation for a music-only device`, () => {
      cy.interceptPql(`GetIOSDevice_v2`, {
        childName: `Huck`,
        deviceType: `iPhone`,
        osVersion: `18.2`,
        musicConnected: true,
      });
      cy.interceptPql(`GetApprovedMusicAlbums`, { albums: [] });

      cy.visit(`/children/user-123/ios-devices/ios-device-123`);

      cy.contains(`Huck's iPhone`);
      cy.contains(`Gertrude Music`);
      cy.contains(`Search Apple Music albums`);
      cy.contains(/Huck.s allowed albums/);
      cy.contains(`No allowed albums yet`);
    });
  });

  describe(`child deletion`, () => {
    it(`redirects to /children path`, () => {
      cy.interceptPql(`GetChild`, mock.child({ id: `user-123` }));
      cy.visit(`/children/user-123`);

      cy.contains(`Delete child`).click();
      cy.testId(`modal-primary-btn`).click();

      // redirects to /children
      cy.location(`pathname`).should(`eq`, `/children`);
    });
  });
});
