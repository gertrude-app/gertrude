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
      cy.interceptPql(`GetMusicCuration`, {
        revision: 0,
        albums: [],
        artists: [],
      });

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
      cy.interceptPql(`GetMusicCuration`, {
        revision: 2,
        albums: [
          {
            id: `album-old`,
            title: `Older Album`,
            artistName: `Album Artist`,
            catalogTrackCount: 10,
            selectedTrackCount: 3,
            scope: `selectedTracks`,
            showsArtwork: true,
            createdAt: `2026-07-01T12:00:00Z`,
          },
        ],
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
      cy.contains(`Current and future eligible releases`);
      cy.contains(`3 tracks allowed`);
    });

    it(`allows an exact track from child-scoped catalog search`, () => {
      cy.interceptPql(`GetIOSDevice_v2`, {
        childName: `Huck`,
        deviceType: `iPhone`,
        osVersion: `18.2`,
        musicConnected: true,
      });
      cy.interceptPql(`GetMusicCuration`, {
        revision: 0,
        albums: [],
        artists: [],
      });
      cy.interceptPql(`SearchMusicCatalog_v2`, {
        revision: 0,
        items: [
          {
            kind: `track`,
            track: {
              id: `track-1`,
              title: `Blinding Lights`,
              artistName: `The Weeknd`,
              preferredAlbumId: `album-1`,
              albumTitle: `After Hours`,
              contentRating: `explicit`,
              appleMusicUrl: `https://music.apple.com/song/track-1`,
              status: { kind: `available`, managementAlbumId: `album-1` },
            },
          },
        ],
      });

      cy.visit(`/children/user-123/ios-devices/ios-device-123`);
      cy.get(`input[name=music-search]`).type(`Blinding Lights`);
      cy.contains(`button`, `Search`).click();
      cy.get(`[data-test=music-search-result]`).within(() => {
        cy.contains(`Blinding Lights`);
        cy.contains(`The Weeknd · After Hours`);
        cy.contains(`Apple Music`);
      });

      const updatedCuration = {
        revision: 1,
        albums: [
          {
            id: `album-1`,
            title: `After Hours`,
            artistName: `The Weeknd`,
            catalogTrackCount: 14,
            selectedTrackCount: 1,
            scope: `selectedTracks` as const,
            showsArtwork: true,
            createdAt: `2026-07-01T12:00:00Z`,
          },
        ],
        artists: [],
      };
      cy.interceptPql(`GetMusicCuration`, updatedCuration);
      cy.interceptPql(`ApproveMusicTrack`, updatedCuration);
      cy.contains(`button`, `Allow track`).click();

      cy.wait(`@ApproveMusicTrack`).its(`request.body`).should(`deep.equal`, {
        childId: `user-123`,
        appleMusicTrackId: `track-1`,
        preferredAlbumId: `album-1`,
      });
      cy.contains(`After Hours`);
      cy.contains(`1 track allowed`);

      cy.contains(`button`, `Clear results`).click();
      cy.get(`[data-test=music-search-result]`).should(`not.exist`);
      cy.get(`[data-test=approved-music-item]`).within(() => {
        cy.contains(`After Hours`);
        cy.contains(`1 track allowed`);
      });
    });

    it(`saves an album checklist as one revision-checked selection`, () => {
      cy.interceptPql(`GetIOSDevice_v2`, {
        childName: `Huck`,
        deviceType: `iPhone`,
        osVersion: `18.2`,
        musicConnected: true,
      });
      cy.interceptPql(`GetMusicCuration`, {
        revision: 4,
        albums: [
          {
            id: `album-1`,
            title: `After Hours`,
            artistName: `The Weeknd`,
            catalogTrackCount: 3,
            selectedTrackCount: 1,
            scope: `selectedTracks`,
            showsArtwork: true,
            createdAt: `2026-07-01T12:00:00Z`,
          },
        ],
        artists: [],
      });
      cy.interceptPql(`GetMusicAlbumCuration`, {
        revision: 4,
        id: `album-1`,
        title: `After Hours`,
        artistName: `The Weeknd`,
        scope: `selectedTracks`,
        selectedTrackCount: 1,
        catalogTrackCount: 3,
        canEdit: true,
        tracks: [
          {
            id: `track-1`,
            title: `Alone Again`,
            artistName: `The Weeknd`,
            discNumber: 1,
            trackNumber: 1,
            durationInMillis: 250_000,
            isSelected: true,
          },
          {
            id: `track-2`,
            title: `Too Late`,
            artistName: `The Weeknd`,
            discNumber: 1,
            trackNumber: 2,
            durationInMillis: 239_000,
            isSelected: false,
          },
          {
            id: `track-3`,
            title: `Hardest to Love`,
            artistName: `The Weeknd`,
            discNumber: 1,
            trackNumber: 3,
            durationInMillis: 211_000,
            isSelected: false,
          },
        ],
      });

      cy.visit(`/children/user-123/ios-devices/ios-device-123`);
      cy.contains(`button`, `Manage tracks`).click();
      cy.get(`[data-test=music-album-modal]`).within(() => {
        cy.contains(`1 track will be allowed`);
        cy.get(`[data-test=music-track-track-2]`).check();
        cy.contains(`2 tracks will be allowed`);
      });

      const updatedCuration = {
        revision: 5,
        albums: [
          {
            id: `album-1`,
            title: `After Hours`,
            artistName: `The Weeknd`,
            catalogTrackCount: 3,
            selectedTrackCount: 2,
            scope: `selectedTracks` as const,
            showsArtwork: true,
            createdAt: `2026-07-01T12:00:00Z`,
          },
        ],
        artists: [],
      };
      cy.interceptPql(`GetMusicCuration`, updatedCuration);
      cy.interceptPql(`SaveMusicAlbumCuration`, {
        status: `updated`,
        curation: updatedCuration,
        album: {
          revision: 5,
          id: `album-1`,
          title: `After Hours`,
          artistName: `The Weeknd`,
          scope: `selectedTracks`,
          selectedTrackCount: 2,
          catalogTrackCount: 3,
          canEdit: true,
          tracks: [
            {
              id: `track-1`,
              title: `Alone Again`,
              artistName: `The Weeknd`,
              discNumber: 1,
              trackNumber: 1,
              durationInMillis: 250_000,
              isSelected: true,
            },
            {
              id: `track-2`,
              title: `Too Late`,
              artistName: `The Weeknd`,
              discNumber: 1,
              trackNumber: 2,
              durationInMillis: 239_000,
              isSelected: true,
            },
            {
              id: `track-3`,
              title: `Hardest to Love`,
              artistName: `The Weeknd`,
              discNumber: 1,
              trackNumber: 3,
              durationInMillis: 211_000,
              isSelected: false,
            },
          ],
        },
      });

      cy.contains(`button`, `Save changes`).click();
      cy.wait(`@SaveMusicAlbumCuration`)
        .its(`request.body`)
        .should(`deep.equal`, {
          childId: `user-123`,
          appleMusicAlbumId: `album-1`,
          expectedRevision: 4,
          selectedTrackIds: [`track-1`, `track-2`],
        });
      cy.get(`[data-test=music-album-modal]`).should(`not.exist`);
      cy.contains(`2 tracks allowed`);
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
