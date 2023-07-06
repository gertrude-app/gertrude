/// <reference types="cypress" />
import * as mock from '../../src/reducers/__tests__/mocks';

describe(`suspend filter request flow`, () => {
  beforeEach(() => {
    cy.simulateLoggedIn();
    cy.interceptPql(
      `GetSuspendFilterRequest`,
      mock.suspendFilterRequest({
        id: `1`,
        requestComment: `I want to watch a video`,
        requestedDurationInSeconds: 60 * 10,
      }),
    );

    cy.interceptPql(`UpdateSuspendFilterRequest`, { success: true });
  });

  it(`handles full happy path for GRANT w/ all redirects`, () => {
    cy.visit(`suspend-filter-requests/1`);
    cy.contains(`I want to watch a video`);

    // dropdown populated from request data, 600 seconds = 10 minutes
    cy.testId(`select-suspension-duration`).contains(`10 minutes`);

    cy.testId(`select-suspension-duration`).find(`button`).click();
    cy.testId(`select-suspension-duration`).contains(`5 minutes`).click();

    // request after save invalidation should come back accepted
    cy.interceptPql(
      `GetSuspendFilterRequest`,
      mock.suspendFilterRequest({ id: `1`, status: `accepted` }),
    );

    cy.testId(`suspend-filter-req-comment`).type(`i'll be watching you`);
    cy.testId(`modal-primary-btn`).click();

    cy.wait(`@UpdateSuspendFilterRequest`).its(`request.body`).should(`deep.equal`, {
      id: `1`,
      durationInSeconds: 300,
      responseComment: `i'll be watching you`,
      status: `accepted`,
    });

    cy.contains(`accepted`);
  });

  it(`handles initialization of custom duration`, () => {
    cy.interceptPql(
      `GetSuspendFilterRequest`,
      mock.suspendFilterRequest({
        id: `1`,
        requestedDurationInSeconds: 60 * 17, // <-- 17 minutes, custom duration
      }),
    );

    cy.visit(`suspend-filter-requests/1`);
    cy.testId(`select-suspension-duration`).contains(`custom duration`);
    cy.contains(`Custom duration (minutes):`);
  });
});
