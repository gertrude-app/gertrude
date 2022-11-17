/// <reference types="cypress" />

declare namespace Cypress {
  interface Chainable {
    simulateLoggedIn(): Chainable<any>;
    testId(selector: string, ...args: any[]): Chainable<any>;
  }
}
