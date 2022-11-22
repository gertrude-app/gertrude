/// <reference types="cypress" />
import GetSuspendFilterRequest from '../fixtures/GetSuspendFilterRequest.json';

describe(`suspend filter request flow`, () => {
  beforeEach(() => {
    cy.simulateLoggedIn();
    cy.intercept(`/graphql/dashboard`, (req) => {
      switch (req.body.operationName) {
        case `GetSuspendFilterRequest`:
          req.reply(GetSuspendFilterRequest);
          break;

        case `UpdateSuspendFilterRequest`:
          req.alias = `updateSuspendFilterRequest`;
          req.reply({ data: { request: { id: `1` } } });
          break;
      }
    });
  });

  it(`handles full happy path for GRANT w/ all redirects`, () => {
    cy.visit(`suspend-filter-requests/1`);
    cy.contains(`I want to watch a video`);

    cy.testId(`suspend-filter-req-comment`).type(`i'll be watching you`);
    cy.testId(`modal-primary-btn`).click();

    cy.wait(`@updateSuspendFilterRequest`)
      .its(`request.body.variables.input.responseComment`)
      .should(`eq`, `i'll be watching you`);
  });
});
