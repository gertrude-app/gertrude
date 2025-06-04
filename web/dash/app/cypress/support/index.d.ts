/// <reference types="cypress" />

import type { interceptPql, forcePqlErr } from './intercept';

declare global {
  namespace Cypress {
    interface Chainable<Subject> {
      simulateLoggedIn(): void;
      testId(selector: string, ...args: any[]): Chainable<Subject>;
      sidebarClick(link: `Dashboard` | `Children` | `Keychains` | `Settings`): void;
      interceptPql: typeof interceptPql;
      forcePqlErr: typeof forcePqlErr;
    }
  }
}
