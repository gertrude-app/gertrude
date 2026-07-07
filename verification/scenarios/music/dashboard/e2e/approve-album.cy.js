/// <reference types="cypress" />

// Intent-level album approval: from the children list, open the music-connected
// device's curation screen, search the live Apple Music catalog, and allow an album.
// Asserts on the approved-albums list / structural hooks, not dashboard copy.
// Exact-copy and component coverage lives in the dashboard's own unit/cypress suites.

const adminId = Cypress.env(`ADMIN_ID`);
const adminToken = Cypress.env(`ADMIN_TOKEN`);
const childName = Cypress.env(`CHILD_NAME`) || `Music Verification Child`;
const searchTerm = Cypress.env(`SEARCH_TERM`) || `Lena Jonsson Trio`;
const albumTitle = Cypress.env(`ALBUM_TITLE`) || `Stories from the Outside`;

function seedAuth(win) {
  win.localStorage.setItem(`admin_id`, adminId);
  win.localStorage.setItem(`admin_token`, adminToken);
  win.localStorage.removeItem(`dev_logged_out`);
}

// the live Apple Music catalog occasionally returns a transient 5xx; retry the
// search a few times (an external-dependency flake, not a dashboard/API defect)
function searchCatalog(triesLeft) {
  cy.get(`input[name="music-search"]`).clear().type(searchTerm);
  cy.contains(`button`, `Search`).click();
  cy.wait(`@search`).then((interception) => {
    if (interception.response.statusCode !== 200 && triesLeft > 0) {
      searchCatalog(triesLeft - 1);
    }
  });
}

describe(`Gertrude Music album approval`, () => {
  it(`approves an Apple Music album for the child from the dashboard`, () => {
    cy.intercept(`POST`, `**/pairql/dashboard/SearchMusicCatalog`).as(`search`);

    cy.visit(`/children`, { onBeforeLoad: seedAuth });

    // open the child's music-connected device -> curation screen (pending devices
    // link elsewhere, so this href only exists once the device is claimed)
    cy.contains(`[data-test=user-card]`, childName)
      .find(`a[href*="/ios-devices/"]`)
      .first()
      .click();

    cy.url().should(`include`, `/ios-devices/`);
    cy.contains(`Search Apple Music albums`); // MusicCuration mounted (not the paywall)

    // critical action: search the live catalog and allow the target album
    searchCatalog(3);

    cy.contains(`.rounded-2xl`, albumTitle) // the result card for the target album
      .contains(`button`, `Allow album`)
      .click();

    // approval persisted: the result button flips to "Allowed" and the album now
    // appears in the approved list (a Remove button only exists for approved albums)
    cy.contains(`.rounded-2xl`, albumTitle).contains(`button`, `Allowed`);
    cy.contains(`button`, `Remove`);
    cy.contains(`No allowed albums yet`).should(`not.exist`);
  });
});
