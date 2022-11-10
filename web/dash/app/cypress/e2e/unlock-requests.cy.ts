/// <reference types="cypress" />
import selectableKeychainsFixture from '../fixtures/selectable-keychains.json';
import unlockRequestFixture from '../fixtures/unlock-request.json';
import userFixture from '../fixtures/user.json';

describe(`unlock request flow`, () => {
  let fetchRes: typeof unlockRequestFixture;
  let userRes: typeof userFixture;
  let keychainsRes: typeof selectableKeychainsFixture;

  beforeEach(() => {
    fetchRes = JSON.parse(JSON.stringify(unlockRequestFixture));
    fetchRes.data.unlockRequest.status = `pending`;
    fetchRes.data.unlockRequest.id = `2`;
    userRes = JSON.parse(JSON.stringify(userFixture));
    userRes.data.user.id = `1`;
    keychainsRes = JSON.parse(JSON.stringify(selectableKeychainsFixture));

    localStorage.setItem(`admin_id`, `be000000-0000-0000-0000-000000000000`);
    localStorage.setItem(`admin_token`, `be000000-0000-0000-0000-000000000000`);

    cy.intercept(`/graphql/dashboard`, (req) => {
      switch (req.body.operationName) {
        case `UnlockRequest`:
          req.reply(fetchRes);
          break;
        case `GetUser`:
          req.reply(userRes);
          break;
        case `GetSelectableKeychains`:
          req.reply(keychainsRes);
          break;
        case `CreateKeyRecord`:
          req.reply({ data: { keyRecord: { id: `123` } } });
          break;
        case `DecideUnlockRequest`:
          req.reply({ data: { unlockRequest: { id: `2` } } });
          break;
      }
    });
  });

  it(`handles full happy path for ACCEPT w/ all redirects`, () => {
    cy.visit(`/users/1/unlock-requests/2`);
    cy.url().should(`include`, `/review`);
    cy.contains(`Accept`).click();
    cy.location(`pathname`).should(`eq`, `/users/1/unlock-requests/2/select-keychain`);
    cy.contains(`Music Theory`).click();
    cy.contains(`Review key`).click();
    cy.location(`pathname`).should(`eq`, `/users/1/unlock-requests/2/edit-key`);
    cy.contains(`Submit`).click();
    cy.location(`pathname`).should(`eq`, `/users/1/unlock-requests/2`);
    cy.contains(`accepted`);
  });

  it(`handles full happy path for DENY w/ all redirects`, () => {
    cy.visit(`/users/1/unlock-requests/2`);
    cy.url().should(`include`, `/review`);
    cy.contains(`Deny`).click();
    cy.contains(`rejected`);
  });

  it(`displays not found error if not found`, () => {
    cy.intercept(`/graphql/dashboard`, { errors: [{ message: `notFound` }] });
    cy.visit(`/users/1/unlock-requests/2-nope`);
    cy.contains(`Unlock request not found`);
  });

  it(`shows generic error for unknown error`, () => {
    cy.intercept(`/graphql/dashboard`, { what: `nope` });
    cy.visit(`/users/1/unlock-requests/2`);
    cy.contains(`try again`);
  });

  it(`shows shows decided status: accepted`, () => {
    fetchRes.data.unlockRequest.status = `accepted`;
    cy.visit(`/users/1/unlock-requests/2`);
    cy.contains(`accepted`);
  });

  it(`shows shows decided status: rejected`, () => {
    fetchRes.data.unlockRequest.status = `rejected`;
    cy.visit(`/users/1/unlock-requests/2`);
    cy.contains(`rejected`);
  });

  it(`redirects to reviewing for pending status`, () => {
    cy.visit(`/users/1/unlock-requests/2`);
    cy.url().should(`include`, `/review`);
  });

  it(`redirects to /unlock-request/:id when review loads non-pending`, () => {
    fetchRes.data.unlockRequest.status = `rejected`;
    cy.visit(`/users/1/unlock-requests/2/review`);
    cy.location(`pathname`).should(`eq`, `/users/1/unlock-requests/2`);
  });

  it(`shows review modal on review screen`, () => {
    fetchRes.data.unlockRequest.requestComment = `please dad!`;
    fetchRes.data.unlockRequest.networkDecision.hostname = `happyfish.com`;
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
    cy.contains(`Misc McStandard Keys`);
  });

  it(`prompts to create a keychain if admin has none`, () => {
    keychainsRes.data.own = [];
    cy.visit(`/users/1/unlock-requests/2/review`);
    cy.contains(`Accept`).click();
    cy.location(`pathname`).should(`eq`, `/users/1/unlock-requests/2/select-keychain`);
    cy.contains(`need a keychain to accept`);
  });

  it(`only shows keychains attached to a user`, () => {
    // make sure our test is actually doing something
    expect(userRes.data.user.keychains.map((k) => k.name)).to.contain(
      `Misc McStandard Keys`,
    );

    // user doesn't have `Misc McStandard Keys` keychain...
    userRes.data.user.keychains = userRes.data.user.keychains.filter(
      (keychain) => keychain.name !== `Misc McStandard Keys`,
    );

    cy.visit(`/users/1/unlock-requests/2/select-keychain`);

    // asserting this first ensures next doesn't pass before render
    cy.contains(`Music Theory`);

    // ... so it shouldn't be in the list
    cy.contains(`Misc McStandard Keys`).should(`not.exist`);
  });

  it(`includes public keychains by admin`, () => {
    localStorage.setItem(`admin_id`, `be000000-0000-0000-0000-000000000000`);
    // simulate that the "HTC" public keychain is owned by the admin
    keychainsRes.data.public[0]!.authorId = `be000000-0000-0000-0000-000000000000`;
    cy.visit(`/users/1/unlock-requests/2/select-keychain`);
    cy.contains(`HTC`);
  });

  it(`shows useful error message on accept failure`, () => {
    cy.visit(`/users/1/unlock-requests/2/edit-key`);
    cy.contains(`Music Theory`).click();
    cy.contains(`Review key`).click();
    cy.intercept(`/graphql/dashboard`, { errors: [{ message: `nope` }] });
    cy.contains(`Submit`).click();
    cy.contains(`Contact support`);
  });

  it(`handles deny flow, starting from deny url`, () => {
    // so when we redirect back to ../, the api says it has been rejected
    fetchRes.data.unlockRequest.status = `rejected`;
    cy.visit(`/users/1/unlock-requests/2/deny`);
    cy.location(`pathname`).should(`eq`, `/users/1/unlock-requests/2`);
    cy.contains(`rejected`);
  });
});
