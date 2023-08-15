/// <reference types="cypress" />
import { dateFromUrl } from '@dash/datetime';
import { time } from '@shared/datetime';
import * as mock from '../../src/reducers/__tests__/mocks';
import { entireDay } from '../../src/lib/days';

describe(`children screen`, () => {
  beforeEach(() => {
    cy.simulateLoggedIn();
    cy.interceptPql(`SaveUser`, { success: true });
    cy.interceptPql(`GetUsers`, [mock.user({ id: `user-123` })]);
    cy.interceptPql(`DeleteEntity`, { success: true });
  });

  describe(`new child creation`, () => {
    it(`creating and updating child`, () => {
      cy.visit(`/children/new`);
      cy.testId(`user-name`).type(`Bo`);

      // simulate freshly saved user from server
      cy.intercept(
        `/pairql/dashboard/GetUser`,
        mock.user({ name: `Bo`, id: `user-123` }),
      );

      cy.contains(`Save child`).click();
      cy.wait(`@SaveUser`);

      cy.testId(`page-heading`).should(`have.text`, `Edit child`);
      cy.contains(`Save child`).should(`be.disabled`);

      cy.testId(`user-name`).type(`az`);

      cy.contains(`Save child`).should(`be.enabled`);
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

  describe(`child deletion`, () => {
    it(`redirects to /children path`, () => {
      cy.interceptPql(`GetUser`, mock.user({ id: `user-123` }));
      cy.visit(`/children/user-123`);

      cy.contains(`Delete child`).click();
      cy.testId(`modal-primary-btn`).click();

      // redirects to /children
      cy.location(`pathname`).should(`eq`, `/children`);
    });
  });

  describe(`combined children screens`, () => {
    it(`summary page displays aggregate totals in correct order`, () => {
      cy.interceptPql(`CombinedUsersActivitySummaries`, [
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

      cy.visit(`/children/activity`);

      cy.contains(`6 out of 26`);
      cy.contains(`5 out of 1234`);
    });

    it(`activity feed displays items in correct order`, () => {
      cy.interceptPql(`CombinedUsersActivityFeed`, [
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

      cy.visit(`/children/activity/03-06-2023`);

      cy.wait(`@CombinedUsersActivityFeed`)
        .its(`request.body`)
        .should(`deep.equal`, { range: entireDay(dateFromUrl(`03-06-2023`)) });

      cy.interceptPql(`DeleteActivityItems_v2`, { success: true });
      cy.interceptPql(`CombinedUsersActivitySummaries`, []);

      // suzy has more items, so her activity should be first
      cy.testId(`page-heading`).first().should(`have.text`, `Suzy’s Activity`);
      cy.testId(`page-heading`).last().should(`have.text`, `Bob’s Activity`);

      cy.contains(`Approve all child activity`).click();

      cy.wait(`@DeleteActivityItems_v2`)
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
