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
      cy.interceptPql(`GetApprovedMusicArtists`, { artists: [] });

      cy.visit(`/children/user-123/ios-devices/ios-device-123`);

      cy.contains(`Huck's iPhone`);
      cy.contains(`Gertrude Music`);
      cy.contains(`Search Apple Music`);
      cy.contains(/Huck.s allowed music/);
      cy.contains(`No allowed music yet`);
    });

    it(`shows allowed music newest first and explains artist grants`, () => {
      cy.interceptPql(`GetIOSDevice_v2`, {
        childName: `Huck`,
        deviceType: `iPhone`,
        osVersion: `18.2`,
        musicConnected: true,
      });
      cy.interceptPql(`GetApprovedMusicAlbums`, {
        albums: [
          {
            id: `album-old`,
            title: `Older Album`,
            artistName: `Album Artist`,
            trackCount: 10,
            showsArtwork: true,
            createdAt: `2026-07-01T12:00:00Z`,
          },
        ],
      });
      cy.interceptPql(`GetApprovedMusicArtists`, {
        artists: [
          {
            id: `artist-new`,
            name: `Newer Artist`,
            catalogMetadata: { genreNames: [] },
            createdAt: `2026-07-09T12:00:00Z`,
          },
        ],
      });

      cy.visit(`/children/user-123/ios-devices/ios-device-123`);

      cy.get(`[data-test=approved-music-item]`)
        .should(`have.length`, 2)
        .then(($items) => {
          const itemText = [...$items].map((item) => item.textContent ?? ``);
          expect(itemText[0]).to.contain(`Newer Artist`);
          expect(itemText[1]).to.contain(`Older Album`);
        });
      cy.contains(`Allows all current and future eligible releases by this artist.`);
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
