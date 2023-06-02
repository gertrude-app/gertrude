/// <reference types="cypress" />
import type {
  UnlockRequest,
  GetSelectableKeychains,
  User,
  KeychainSummary,
} from '@dash/types';
import { betsy } from '../fixtures/helpers';
import * as mock from '../../src/reducers/__tests__/mocks';

describe(`unlock request flow`, () => {
  let unlockRequest: UnlockRequest;
  let user: User;
  let selectable: GetSelectableKeychains.Output;
  let keychain: KeychainSummary;

  beforeEach(() => {
    cy.simulateLoggedIn();

    keychain = mock.keychainSummary({
      id: `keychain-id`,
      authorId: betsy.id,
      name: `Music Theory`,
    });
    user = mock.user({ id: `1`, keychains: [keychain] });
    selectable = { own: [keychain], public: [] };
    unlockRequest = mock.unlockRequest({ id: `2`, userId: `1` });

    cy.intercept(`/pairql/dashboard/GetUnlockRequest`, (req) => req.reply(unlockRequest));
    cy.intercept(`/pairql/dashboard/GetUser`, (req) => req.reply(user));
    cy.intercept(`/pairql/dashboard/GetIdentifiedApps`, [mock.identifiedApp()]);
    cy.intercept(`/pairql/dashboard/GetSelectableKeychains`, (req) =>
      req.reply(selectable),
    );
    cy.intercept(`/pairql/dashboard/SaveKey`, { success: true });
    cy.intercept(`/pairql/dashboard/UpdateUnlockRequest`, (req) => {
      req.alias = `updateUnlockRequest`;
      req.reply({ success: true });
    });
  });

  it(`handles full happy path for ACCEPT w/ all redirects`, () => {
    cy.visit(`/users/1/unlock-requests/2`);
    cy.url().should(`include`, `/review`);
    cy.contains(`Accept`).click();
    cy.location(`pathname`).should(`eq`, `/users/1/unlock-requests/2/select-keychain`);
    cy.contains(`Music Theory`).click();
    cy.contains(`Review key`).click();
    cy.location(`pathname`).should(
      `eq`,
      `/users/1/unlock-requests/2/edit-key/keychain-id`,
    );

    // server should now say it's been accepted when it refetches
    cy.intercept(
      `/pairql/dashboard/GetUnlockRequest`,
      mock.unlockRequest({ id: `2`, userId: `1`, status: `accepted` }),
    );

    cy.contains(`Submit`).click();
    cy.location(`pathname`).should(`eq`, `/users/1/unlock-requests/2`);
    cy.contains(`accepted`);
  });

  it(`handles full happy path for DENY w/ all redirects`, () => {
    cy.visit(`/users/1/unlock-requests/2`);
    cy.url().should(`include`, `/review`);
    cy.contains(`Deny`).click();
    cy.location(`pathname`).should(`eq`, `/users/1/unlock-requests/2/deny`);
    cy.contains(`comment`);
    cy.testId(`deny-unlock-req-comment`).type(`nope`);

    // server should say it's been rejected when it refetches
    cy.intercept(
      `/pairql/dashboard/GetUnlockRequest`,
      mock.unlockRequest({ id: `2`, userId: `1`, status: `rejected` }),
    );

    cy.contains(`Deny`).click();
    cy.wait(`@updateUnlockRequest`)
      .its(`request.body.responseComment`)
      .should(`eq`, `nope`);
    cy.contains(`rejected`);
  });

  it(`shows empty state if admin has no personal keychains to assign`, () => {
    user = mock.user({ id: `1`, keychains: [] });
    cy.intercept(`/pairql/dashboard/GetUser`, (req) => req.reply(user));
    cy.visit(`/users/1/unlock-requests/2`);
    cy.url().should(`include`, `/review`);
    cy.contains(`Accept`).click();
    cy.location(`pathname`).should(`eq`, `/users/1/unlock-requests/2/select-keychain`);
    cy.contains(`No keychains`);
  });

  it(`shows alternate empty state if user has no personal keychains, but the admin has at least one they could assign`, () => {
    user = mock.user({ id: `1`, keychains: [] });
    cy.intercept(`/pairql/dashboard/GetUser`, (req) => req.reply(user));
    selectable.own = [];
    cy.visit(`/users/1/unlock-requests/2`);
    cy.url().should(`include`, `/review`);
    cy.contains(`Accept`).click();
    cy.location(`pathname`).should(`eq`, `/users/1/unlock-requests/2/select-keychain`);
    cy.contains(`No keychains`);
  });

  it(`displays not found error if not found`, () => {
    cy.intercept(`/pairql/dashboard/GetUnlockRequest`, {
      __cyStubbedError: true,
      type: `notFound`,
      entityName: `Unlock request`,
    });
    cy.visit(`/users/1/unlock-requests/2-nope`);
    cy.contains(`Unlock request not found`);
  });

  it(`shows generic error for unknown error`, () => {
    cy.intercept(`/pairql/dashboard/GetUnlockRequest`, {
      __cyStubbedError: true,
      type: `serverError`,
    });
    cy.visit(`/users/1/unlock-requests/2`);
    cy.contains(`try again`);
  });

  it(`shows decided status: accepted`, () => {
    unlockRequest.status = `accepted`;
    cy.visit(`/users/1/unlock-requests/2`);
    cy.contains(`accepted`);
  });

  it(`shows decided status: rejected`, () => {
    unlockRequest.status = `rejected`;
    cy.visit(`/users/1/unlock-requests/2`);
    cy.contains(`rejected`);
  });

  it(`redirects to reviewing for pending status`, () => {
    cy.visit(`/users/1/unlock-requests/2`);
    cy.url().should(`include`, `/review`);
  });

  it(`redirects to /unlock-request/:id when review loads non-pending`, () => {
    unlockRequest.status = `rejected`;
    cy.visit(`/users/1/unlock-requests/2/review`);
    cy.location(`pathname`).should(`eq`, `/users/1/unlock-requests/2`);
  });

  it(`shows review modal on review screen`, () => {
    unlockRequest.requestComment = `please dad!`;
    unlockRequest.domain = `happyfish.com`;
    cy.visit(`/users/1/unlock-requests/2/review`);
    cy.contains(`please dad!`);
    cy.contains(`happyfish.com`);
  });

  it(`goes to select keychain screen when review accept clicked`, () => {
    cy.visit(`/users/1/unlock-requests/2/review`);
    cy.contains(`Accept`).click();
    cy.location(`pathname`).should(`eq`, `/users/1/unlock-requests/2/select-keychain`);
    cy.contains(`Select a keychain`);
    cy.contains(`Music Theory`);
  });

  it(`only shows keychains attached to a user`, () => {
    const keychain2 = mock.keychainSummary({
      authorId: betsy.id,
      name: `Misc McStandard Keys`,
    });

    user = mock.user({ id: `1`, keychains: [keychain] }); // <-- doesn't have keychain2
    selectable = { own: [keychain, keychain2], public: [] };

    cy.visit(`/users/1/unlock-requests/2/select-keychain`);

    // asserting this first ensures next doesn't pass before render
    cy.contains(`Music Theory`);

    // ... so it shouldn't be in the list
    cy.contains(`Misc McStandard Keys`).should(`not.exist`);
  });

  it(`includes public keychains by admin`, () => {
    const htc = mock.keychainSummary({
      isPublic: true,
      authorId: betsy.id, // <--  admin owns the public keychain
      name: `HTC`,
    });

    selectable = { own: [keychain, htc], public: [htc] };
    user = mock.user({ id: `1`, keychains: [keychain, htc] });
    cy.visit(`/users/1/unlock-requests/2/select-keychain`);
    cy.contains(`HTC`);
  });

  it(`shows useful error message on accept failure`, () => {
    cy.visit(`/users/1/unlock-requests/2/select-keychain`);
    cy.contains(`Music Theory`).click();
    cy.contains(`Review key`).click();
    cy.intercept(`/pairql/dashboard/UpdateUnlockRequest`, {
      __cyStubbedError: true,
      type: `serverError`,
    });
    cy.contains(`Submit`).click();
    cy.contains(`Contact support`);
  });

  it(`handles deny flow, starting from deny url`, () => {
    cy.visit(`/users/1/unlock-requests/2/deny`);

    // server should say it's been rejected when it refetches
    cy.intercept(
      `/pairql/dashboard/GetUnlockRequest`,
      mock.unlockRequest({ id: `2`, userId: `1`, status: `rejected` }),
    );

    cy.contains(`Deny`).click();
    cy.location(`pathname`).should(`eq`, `/users/1/unlock-requests/2`);
    cy.contains(`rejected`);
  });

  it(`improves ux by leveraging unlock request source`, () => {
    unlockRequest.url = `https://music.jwpcdn.com/player/v/8.26.2/gapro.js`;
    unlockRequest.domain = `music.jwpcdn.com`;
    cy.visit(`/users/1/unlock-requests/2/select-keychain`);
    cy.contains(`Music Theory`).click();
    cy.contains(`Review key`).click();
    cy.contains(`jwpcdn.com`).click();

    cy.testId(`unlock-request-src`).should(`contain`, unlockRequest.url);

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
