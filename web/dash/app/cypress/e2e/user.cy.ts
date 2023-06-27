/// <reference types="cypress" />
import { dateFromUrl } from '@dash/datetime';
import { time } from '@shared/datetime';
import * as mock from '../../src/reducers/__tests__/mocks';
import { entireDay } from '../../src/lib/days';

describe(`user screen`, () => {
  beforeEach(() => {
    cy.simulateLoggedIn();

    cy.intercept(`/pairql/dashboard/SaveUser`, (req) => {
      req.alias = `saveUser`;
      req.reply({ success: true });
    });

    cy.intercept(`/pairql/dashboard/GetUsers`, [mock.user({ id: `user-123` })]);

    cy.intercept(`/pairql/dashboard/DeleteEntity`, { success: true });
  });

  describe(`new user creation`, () => {
    it(`creating and updating user`, () => {
      cy.visit(`/users/new`);
      cy.testId(`user-name`).type(`Bo`);

      // simulate freshly saved user from server
      cy.intercept(
        `/pairql/dashboard/GetUser`,
        mock.user({ name: `Bo`, id: `user-123` }),
      );

      cy.contains(`Save user`).click();
      cy.wait(`@saveUser`);

      cy.testId(`page-heading`).should(`have.text`, `Edit user`);
      cy.contains(`Save user`).should(`be.disabled`);

      cy.testId(`user-name`).type(`az`);

      cy.contains(`Save user`).should(`be.enabled`);
    });

    it(`redirects to new uuid path & doesn't list unsaved new user`, () => {
      cy.visit(`/users/new`);

      // redirects to /users/<new-user-id>
      cy.location(`pathname`).should(`not.eq`, `/users/new`);
      cy.contains(`Create user`);

      // don't show the empty new user in the list
      cy.sidebarClick(`Users`);
      cy.testId(`user-card`).should(`have.length`, 1);
    });
  });

  describe(`user deletion`, () => {
    it(`redirects to /users path`, () => {
      cy.intercept(`/pairql/dashboard/GetUser`, mock.user({ id: `user-123` }));
      cy.visit(`/users/user-123`);

      cy.contains(`Delete user`).click();
      cy.testId(`modal-primary-btn`).click();

      // redirects to /users
      cy.location(`pathname`).should(`eq`, `/users`);
    });
  });

  describe(`combined users screens`, () => {
    it(`summary page displays aggregate totals in correct order`, () => {
      cy.intercept(`/pairql/dashboard/CombinedUsersActivitySummaries`, [
        {
          date: time.subtracting({ days: 1 }),
          numApproved: 5,
          totalItems: 1234,
        },
        {
          date: time.now(),
          numApproved: 6,
          totalItems: 26,
        },
      ]);

      cy.visit(`/users/activity`);

      cy.contains(`6 out of 26`);
      cy.contains(`5 out of 1234`);
    });

    it(`activity feed displays items in correct order`, () => {
      cy.intercept(`/pairql/dashboard/CombinedUsersActivityFeed`, (req) => {
        req.alias = `combinedUsersActivityFeed`;
        req.reply([
          {
            userName: `Bob`,
            numDeleted: 0,
            items: [mock.screenshotActivityItem({ id: `screenshot-123` })],
          },
          {
            userName: `Suzy`,
            numDeleted: 1,
            items: [
              mock.screenshotActivityItem({ id: `screenshot-234` }),
              mock.screenshotActivityItem({ id: `screenshot-345` }),
              mock.screenshotActivityItem({ id: `screenshot-456` }),
              mock.keystrokeActivityItem({
                id: `ks-1`,
                ids: [`ks-1`, `ks-2`, `ks-3`], // <-- aggregated ids
                appName: `Firefox`,
                line: `ChatGPT, tell me how to link vapor and lib-bsm with a simlink decorator`,
              }),
            ],
          },
        ]);
      });

      cy.visit(`/users/activity/03-06-2023`);

      cy.wait(`@combinedUsersActivityFeed`)
        .its(`request.body`)
        .should(`deep.equal`, { range: entireDay(dateFromUrl(`03-06-2023`)) });

      cy.intercept(`/pairql/dashboard/DeleteActivityItems_v2`, (req) => {
        req.alias = `deleteActivityItems`;
        req.reply({ success: true });
      });

      // suzy has more items, so her activity should be first
      cy.testId(`page-heading`).first().should(`have.text`, `Suzy’s Activity`);
      cy.testId(`page-heading`).last().should(`have.text`, `Bob’s Activity`);

      cy.contains(`Approve all user activity`).click();

      cy.wait(`@deleteActivityItems`)
        .its(`request.body`)
        .should(`deep.equal`, {
          keystrokeLineIds: [`ks-1`, `ks-2`, `ks-3`], // <-- aggregated ids
          screenshotIds: [
            `screenshot-123`,
            `screenshot-234`,
            `screenshot-345`,
            `screenshot-456`,
          ],
        });
    });
  });
});
