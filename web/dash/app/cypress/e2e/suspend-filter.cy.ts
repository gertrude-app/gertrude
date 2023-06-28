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
      }),
    );

    cy.interceptPql(`UpdateSuspendFilterRequest`, { success: true });
  });

  it(`handles full happy path for GRANT w/ all redirects`, () => {
    cy.visit(`suspend-filter-requests/1`);
    cy.contains(`I want to watch a video`);

    cy.testId(`suspend-filter-req-comment`).type(`i'll be watching you`);
    cy.testId(`modal-primary-btn`).click();

    cy.wait(`@UpdateSuspendFilterRequest`)
      .its(`request.body.responseComment`)
      .should(`eq`, `i'll be watching you`);
  });
});
