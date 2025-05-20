/// <reference types="cypress" />
import { dateFromUrl } from '@dash/datetime';
import { time } from '@shared/datetime';
import * as mock from '../../src/reducers/__tests__/mocks';
import { entireDay } from '../../src/lib/days';

describe(`activity screens`, () => {
  beforeEach(() => {
    cy.simulateLoggedIn();
    cy.interceptPql(`DeleteActivityItems_v2`, { success: true });
  });

  it(`summary page displays aggregate totals in correct order`, () => {
    cy.interceptPql(`CombinedUsersActivitySummaries`, [
      {
        date: time.subtracting({ days: 1 }),
        numApproved: 5,
        numTotal: 1234,
        numFlagged: 0,
      },
      {
        date: time.now(),
        numApproved: 6,
        numTotal: 26,
        numFlagged: 0,
      },
    ]);

    cy.visit(`/children/activity`);

    cy.contains(`6 out of 26`);
    cy.contains(`5 out of 1234`);
  });

  it(`activity feed displays items in correct order`, () => {
    cy.interceptPql(`CombinedUsersActivityFeed`, [
      {
        showSuspensionActivity: false,
        userName: `Bob`,
        numDeleted: 0,
        items: [
          mock.screenshotActivityItem({ id: `screenshot-123`, duringSuspension: true }),
        ],
      },
      {
        showSuspensionActivity: true,
        userName: `Suzy`,
        numDeleted: 1,
        items: [
          mock.screenshotActivityItem({ id: `screenshot-234` }),
          mock.screenshotActivityItem({ id: `screenshot-345`, duringSuspension: true }),
          mock.screenshotActivityItem({ id: `screenshot-456`, duringSuspension: true }),
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

    cy.interceptPql(`CombinedUsersActivitySummaries`, []);

    // suzy has more items, so her activity should be first
    cy.testId(`page-heading`).first().should(`have.text`, `Suzy’s Activity`);
    cy.testId(`page-heading`).last().should(`have.text`, `Bob’s Activity`);

    cy.testId(`single-user-sub-feed`).first().contains(`During filter suspension`);
    // bob has `showSuspensionActivity: false`, so his feed should not have any highlighted suspension items
    cy.testId(`single-user-sub-feed`)
      .last()
      .contains(`During filter suspension`)
      .should(`not.exist`);

    cy.contains(`Delete all activity`).click();

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

  it(`deleting chunk of items does not change order`, () => {
    const suzysItems = Array.from({ length: 40 }, (_, i) =>
      mock.keystrokeActivityItem({
        id: `s${i}`,
        ids: [`s${i}`],
        appName: `App`,
        line: `suzy typing ${i}`,
      }),
    );
    cy.interceptPql(`CombinedUsersActivityFeed`, [
      {
        showSuspensionActivity: true,
        userName: `suzy`,
        numDeleted: 0,
        items: suzysItems,
      },
      {
        showSuspensionActivity: true,
        userName: `jimmy`,
        numDeleted: 0,
        items: Array.from({ length: 130 }, (_, i) =>
          mock.keystrokeActivityItem({
            id: `j${i}`,
            ids: [`j${i}`],
            appName: `App`,
            line: `jimmy typing ${i}`,
          }),
        ),
      },
    ]);

    cy.visit(`/children/activity/03-06-2023`);

    cy.testId(`page-heading`).first().should(`have.text`, `jimmy’s Activity`);
    cy.testId(`page-heading`).last().should(`have.text`, `suzy’s Activity`);

    cy.interceptPql(`CombinedUsersActivityFeed`, [
      {
        showSuspensionActivity: true,
        userName: `suzy`,
        numDeleted: 0,
        items: suzysItems,
      },
      {
        showSuspensionActivity: true,
        userName: `jimmy`,
        numDeleted: 0,
        //                          vv -- only 30 remain
        items: Array.from({ length: 30 }, (_, i) =>
          mock.keystrokeActivityItem({
            id: `j${i + 100}`,
            ids: [`j${i + 100}`],
            appName: `App`,
            line: `jimmy typing ${i + 100}`,
          }),
        ),
      },
    ]);

    // delete jimmy's first 100 items...
    cy.contains(`Delete previous 100 items`).click();

    // ...and the rest of jimmy's activity should still be first, though outnumbered
    cy.testId(`page-heading`).first().should(`have.text`, `jimmy’s Activity`);
    cy.testId(`page-heading`).last().should(`have.text`, `suzy’s Activity`);
  });
});
