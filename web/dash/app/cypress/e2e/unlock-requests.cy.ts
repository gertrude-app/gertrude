/// <reference types="cypress" />
import type { KeychainSummary } from '@dash/types';
import { betsy } from '../fixtures/helpers';
import * as mock from '../../src/reducers/__tests__/mocks';

describe(`unlock request flow`, () => {
  let keychain: KeychainSummary;

  beforeEach(() => {
    cy.simulateLoggedIn();

    keychain = mock.keychainSummary({
      id: `keychain-id`,
      authorId: betsy.id,
      name: `Music Theory`,
    });

    cy.interceptPql(`GetUnlockRequest`, mock.unlockRequest({ id: `2`, userId: `1` }));
    cy.interceptPql(`GetUser`, mock.user({ id: `1`, keychains: [keychain] }));
    cy.interceptPql(`GetIdentifiedApps`, [mock.identifiedApp()]);
    cy.interceptPql(`GetSelectableKeychains`, { own: [keychain], public: [] });
    cy.interceptPql(`SaveKey`, { success: true });
    cy.interceptPql(`UpdateUnlockRequest`, { success: true });
  });

  it(`handles full happy path for ACCEPT w/ all redirects`, () => {
    cy.visit(`/children/1/unlock-requests/2`);
    cy.url().should(`include`, `/review`);
    cy.contains(`Accept`).click();
    cy.location(`pathname`).should(`eq`, `/children/1/unlock-requests/2/select-keychain`);
    cy.contains(`Music Theory`).click();
    cy.contains(`Review key`).click();
    cy.location(`pathname`).should(
      `eq`,
      `/children/1/unlock-requests/2/edit-key/keychain-id`,
    );

    // server should now say it's been accepted when it refetches
    cy.interceptPql(
      `GetUnlockRequest`,
      mock.unlockRequest({ id: `2`, userId: `1`, status: `accepted` }),
    );

    cy.contains(`Submit`).click();
    cy.location(`pathname`).should(`eq`, `/children/1/unlock-requests/2`);
    cy.contains(`accepted`);
  });

  it(`handles full happy path for DENY w/ all redirects`, () => {
    cy.visit(`/children/1/unlock-requests/2`);
    cy.url().should(`include`, `/review`);
    cy.contains(`Deny`).click();
    cy.location(`pathname`).should(`eq`, `/children/1/unlock-requests/2/deny`);
    cy.contains(`comment`);
    cy.testId(`deny-unlock-req-comment`).type(`nope`);

    // server should say it's been rejected when it refetches
    cy.interceptPql(
      `GetUnlockRequest`,
      mock.unlockRequest({ id: `2`, userId: `1`, status: `rejected` }),
    );

    cy.contains(`Deny`).click();
    cy.wait(`@UpdateUnlockRequest`)
      .its(`request.body.responseComment`)
      .should(`eq`, `nope`);
    cy.contains(`rejected`);
  });

  it(`shows empty state if parent has no personal keychains to assign`, () => {
    cy.interceptPql(`GetUser`, mock.user({ id: `1`, keychains: [] }));
    cy.visit(`/children/1/unlock-requests/2`);
    cy.url().should(`include`, `/review`);
    cy.contains(`Accept`).click();
    cy.location(`pathname`).should(`eq`, `/children/1/unlock-requests/2/select-keychain`);
    cy.contains(`No keychains`);
  });

  it(`shows alternate empty state if child has no personal keychains, but the parent has at least one they could assign`, () => {
    cy.interceptPql(`GetUser`, mock.user({ id: `1`, keychains: [] }));
    cy.interceptPql(`GetSelectableKeychains`, { own: [], public: [] });
    cy.visit(`/children/1/unlock-requests/2`);
    cy.url().should(`include`, `/review`);
    cy.contains(`Accept`).click();
    cy.location(`pathname`).should(`eq`, `/children/1/unlock-requests/2/select-keychain`);
    cy.contains(`No keychains`);
  });

  it(`displays not found error if not found`, () => {
    cy.forcePqlErr(`GetUnlockRequest`, {
      type: `notFound`,
      entityName: `Unlock request`,
    });
    cy.visit(`/children/1/unlock-requests/2-nope`);
    cy.contains(`Unlock request not found`);
  });

  it(`shows generic error for unknown error`, () => {
    cy.forcePqlErr(`GetUnlockRequest`, { type: `serverError` });
    cy.visit(`/children/1/unlock-requests/2`);
    cy.contains(`try again`);
  });

  it(`shows decided status: accepted`, () => {
    cy.interceptPql(
      `GetUnlockRequest`,
      mock.unlockRequest({ id: `2`, userId: `1`, status: `accepted` }),
    );
    cy.visit(`/children/1/unlock-requests/2`);
    cy.contains(`accepted`);
  });

  it(`shows decided status: rejected`, () => {
    cy.interceptPql(
      `GetUnlockRequest`,
      mock.unlockRequest({ id: `2`, userId: `1`, status: `rejected` }),
    );
    cy.visit(`/children/1/unlock-requests/2`);
    cy.contains(`rejected`);
  });

  it(`redirects to reviewing for pending status`, () => {
    cy.visit(`/children/1/unlock-requests/2`);
    cy.url().should(`include`, `/review`);
  });

  it(`redirects to /unlock-request/:id when review loads non-pending`, () => {
    cy.interceptPql(
      `GetUnlockRequest`,
      mock.unlockRequest({ id: `2`, userId: `1`, status: `rejected` }),
    );
    cy.visit(`/children/1/unlock-requests/2/review`);
    cy.location(`pathname`).should(`eq`, `/children/1/unlock-requests/2`);
  });

  it(`shows review modal on review screen`, () => {
    cy.interceptPql(
      `GetUnlockRequest`,
      mock.unlockRequest({
        id: `2`,
        userId: `1`,
        requestComment: `please dad!`,
        domain: `happyfish.com`,
      }),
    );
    cy.visit(`/children/1/unlock-requests/2/review`);
    cy.contains(`please dad!`);
    cy.contains(`happyfish.com`);
  });

  it(`goes to select keychain screen when review accept clicked`, () => {
    cy.visit(`/children/1/unlock-requests/2/review`);
    cy.contains(`Accept`).click();
    cy.location(`pathname`).should(`eq`, `/children/1/unlock-requests/2/select-keychain`);
    cy.contains(`Select a keychain`);
    cy.contains(`Music Theory`);
  });

  it(`only shows keychains attached to a child`, () => {
    const keychain2 = mock.keychainSummary({
      authorId: betsy.id,
      name: `Misc McStandard Keys`,
    });

    // doesn't have keychain2
    cy.interceptPql(`GetUser`, mock.user({ id: `1`, keychains: [keychain] }));
    cy.interceptPql(`GetSelectableKeychains`, { own: [keychain, keychain2], public: [] });

    cy.visit(`/children/1/unlock-requests/2/select-keychain`);

    // asserting this first ensures next doesn't pass before render
    cy.contains(`Music Theory`);

    // ... so it shouldn't be in the list
    cy.contains(`Misc McStandard Keys`).should(`not.exist`);
  });

  it(`includes public keychains by parent`, () => {
    const htc = mock.keychainSummary({
      isPublic: true,
      authorId: betsy.id, // <--  parent owns the public keychain
      name: `HTC`,
    });

    cy.interceptPql(`GetUser`, mock.user({ id: `1`, keychains: [keychain, htc] }));
    cy.interceptPql(`GetSelectableKeychains`, { own: [keychain, htc], public: [htc] });
    cy.visit(`/children/1/unlock-requests/2/select-keychain`);
    cy.contains(`HTC`);
  });

  it(`shows useful error message on accept failure`, () => {
    cy.visit(`/children/1/unlock-requests/2/select-keychain`);
    cy.contains(`Music Theory`).click();
    cy.contains(`Review key`).click();
    cy.forcePqlErr(`UpdateUnlockRequest`, { type: `serverError` });
    cy.contains(`Submit`).click();
    cy.contains(`Contact support`);
  });

  it(`handles deny flow, starting from deny url`, () => {
    cy.visit(`/children/1/unlock-requests/2/deny`);

    // server should say it's been rejected when it refetches
    cy.interceptPql(
      `GetUnlockRequest`,
      mock.unlockRequest({ id: `2`, userId: `1`, status: `rejected` }),
    );

    cy.contains(`Deny`).click();
    cy.location(`pathname`).should(`eq`, `/children/1/unlock-requests/2`);
    cy.contains(`rejected`);
  });

  it(`improves ux by leveraging unlock request source`, () => {
    cy.interceptPql(
      `GetUnlockRequest`,
      mock.unlockRequest({
        id: `2`,
        userId: `1`,
        url: `https://music.jwpcdn.com/player/v/8.26.2/gapro.js`,
        domain: `music.jwpcdn.com`,
      }),
    );
    cy.visit(`/children/1/unlock-requests/2/select-keychain`);
    cy.contains(`Music Theory`).click();
    cy.contains(`Review key`).click();
    cy.contains(`jwpcdn.com`).click();

    cy.testId(`unlock-request-src`).should(
      `contain`,
      `https://music.jwpcdn.com/player/v/8.26.2/gapro.js`,
    );

    cy.testId(`address-type`).within(() => {
      cy.get(`button`).click();
      cy.contains(`Strict`).click();
    });

    // we should get the full hostname with subdomain
    cy.testId(`key-address`).should(`have.value`, `music.jwpcdn.com`);

    cy.testId(`address-type`).within(() => {
      cy.get(`button`).click();
      cy.contains(`Standard`).click();
    });

    // hostname is eliminated again for a simpler `standard` type
    cy.testId(`key-address`).should(`have.value`, `jwpcdn.com`);
  });
});
