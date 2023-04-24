/// <reference types="cypress" />
import { dateFromUrl } from '@dash/datetime';
import { time } from '@shared/datetime';
import * as mock from '../../src/redux/__tests__/mocks';
import { entireDay } from '../../src/lib/helpers';

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

      cy.contains(`Save user`).click();
      cy.wait(`@saveUser`);

      cy.testId(`page-heading`).should(`have.text`, `Edit user`);
      cy.contains(`Save user`).should(`be.disabled`);

      cy.testId(`user-name`).type(`az`);
      cy.contains(`Save user`).should(`be.enabled`).click();
      cy.wait(`@saveUser`);

      cy.sidebarClick(`Users`);
      cy.contains(`Boaz`);
      cy.testId(`user-card`).should(`have.length`, 2);
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
      cy.visit(`/users`);
      cy.contains(`Edit`).click();

      cy.contains(`Delete user`).click();
      cy.testId(`modal-primary-btn`).click();

      // redirects to /users
      cy.location(`pathname`).should(`eq`, `/users`);
    });
  });

  describe(`all users activity`, () => {
    it(`overviews page`, () => {
      cy.intercept(`/pairql/dashboard/CombinedUsersActivitySummaries`, [
        mock.combinedUsersActivitySummary({
          userId: `1`,
          days: [
            mock.userActivitySummary(10, 4, time.now()),
            mock.userActivitySummary(1234, 5, time.subtracting({ days: 1 })),
          ],
        }),
        mock.combinedUsersActivitySummary({
          userId: `456`,
          userName: `Suzy`,
          days: [mock.userActivitySummary(16, 2, time.now())],
        }),
      ]);

      cy.visit(`/users/activity`);

      cy.contains(`6 out of 26`);
      cy.contains(`5 out of 1234`);
    });

    it(`review day`, () => {
      const ids = [
        `a70ab833-d7c5-4eb0-8a86-83738188bec0`,
        `ff285ff7-28d8-43f6-8ecd-bb6c3037196c`,
        `359741a3-b61c-456e-a50b-47cc4abfc33a`,
      ];
      cy.intercept(`/pairql/dashboard/CombinedUsersActivityFeed`, (req) => {
        req.alias = `combinedUsersActivityFeed`;
        req.reply([
          mock.combinedUsersActivityFeed(),
          mock.combinedUsersActivityFeed({
            userName: `Suzy`,
            numDeleted: 1,
            items: [
              {
                type: `CoalescedKeystrokeLine`,
                value: {
                  id: ids[0],
                  ids: ids,
                  appName: `Firefox`,
                  line: `ChatGPT, tell me how to link vapor and lib-bsm with a simlink decorator`,
                  createdAt: new Date().toISOString(),
                },
              },
            ],
          }),
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

      cy.contains(`Approve all Suzy’s activity`).click();

      cy.wait(`@deleteActivityItems`).its(`request.body`).should(`deep.equal`, {
        keystrokeLineIds: ids,
        screenshotIds: [],
      });
    });
  });
});
