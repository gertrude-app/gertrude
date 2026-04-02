/// <reference types="cypress" />
import type { KeychainSummary, UnlockRequest } from '@dash/types';
import * as mock from '../../src/reducers/__tests__/mocks';
import { betsy } from '../fixtures/helpers';

describe(`batch unlock requests flow`, () => {
  let keychain: KeychainSummary;

  function makeRequest(override: Partial<UnlockRequest> = {}): UnlockRequest {
    return mock.unlockRequest({
      userId: `child-1`,
      userName: `Huck`,
      status: `pending`,
      ...override,
    });
  }

  beforeEach(() => {
    cy.simulateLoggedIn();
    keychain = mock.keychainSummary({
      id: `keychain-1`,
      parentId: betsy.id,
      name: `School`,
    });
    cy.interceptPql(`HandleUnlockRequests`, { success: true });
  });

  it(`shows empty state when no pending requests`, () => {
    cy.interceptPql(`GetBatchUnlockRequestData`, { requests: [], keychains: [keychain] });
    cy.visit(`/children/child-1/unlock-requests`);
    cy.contains(`No pending unlock requests`);
  });

  it(`displays batch UI with multiple requests`, () => {
    cy.interceptPql(`GetBatchUnlockRequestData`, {
      requests: [
        makeRequest({ domain: `khanacademy.org`, url: `https://khanacademy.org/math` }),
        makeRequest({ domain: `docs.google.com`, url: `https://docs.google.com/doc/1` }),
        makeRequest({
          domain: `coolmath.com`,
          url: `https://coolmath.com/games`,
          requestComment: `need this for homework`,
        }),
      ],
      keychains: [keychain],
    });
    cy.visit(`/children/child-1/unlock-requests`);
    cy.contains(`khanacademy.org`);
    cy.contains(`docs.google.com`);
    cy.contains(`coolmath.com`);
    cy.contains(`need this for homework`);
  });

  it(`submits batch accept for all requests`, () => {
    cy.interceptPql(`GetBatchUnlockRequestData`, {
      requests: [
        makeRequest({ id: `req-1`, domain: `khanacademy.org` }),
        makeRequest({ id: `req-2`, domain: `coolmath.com` }),
      ],
      keychains: [keychain],
    });
    cy.visit(`/children/child-1/unlock-requests`);
    cy.contains(`Submit`).click();
    cy.wait(`@HandleUnlockRequests`)
      .its(`request.body`)
      .should((body) => {
        expect(body.decisions).to.have.length(2);
        expect(body.decisions[0].status).to.eq(`accepted`);
        expect(body.decisions[1].status).to.eq(`accepted`);
      });
  });

  it(`can deny individual requests`, () => {
    cy.interceptPql(`GetBatchUnlockRequestData`, {
      requests: [
        makeRequest({ id: `req-1`, domain: `khanacademy.org` }),
        makeRequest({ id: `req-2`, domain: `coolmath.com` }),
      ],
      keychains: [keychain],
    });
    cy.visit(`/children/child-1/unlock-requests`);
    cy.contains(`khanacademy.org`)
      .closest(`tr, [class*="border"]`)
      .contains(`Deny`)
      .click();
    cy.contains(`Submit`).click();
    cy.wait(`@HandleUnlockRequests`)
      .its(`request.body`)
      .should((body) => {
        expect(body.decisions.some((d: any) => d.status === `rejected`)).to.eq(true);
        expect(body.decisions.some((d: any) => d.status === `accepted`)).to.eq(true);
      });
  });

  it(`deny all button sets all rows to deny`, () => {
    cy.interceptPql(`GetBatchUnlockRequestData`, {
      requests: [
        makeRequest({ id: `req-1`, domain: `khanacademy.org` }),
        makeRequest({ id: `req-2`, domain: `coolmath.com` }),
      ],
      keychains: [keychain],
    });
    cy.visit(`/children/child-1/unlock-requests`);
    cy.contains(`Deny all`).click();
    cy.contains(`Submit`).click();
    cy.wait(`@HandleUnlockRequests`)
      .its(`request.body`)
      .should((body) => {
        expect(body.decisions.every((d: any) => d.status === `rejected`)).to.eq(true);
      });
  });

  it(`shows single request without bulk action buttons`, () => {
    cy.interceptPql(`GetBatchUnlockRequestData`, {
      requests: [makeRequest({ id: `req-1`, domain: `example.com` })],
      keychains: [keychain],
    });
    cy.visit(`/children/child-1/unlock-requests`);
    cy.contains(`example.com`);
    cy.contains(`Deny all`).should(`not.exist`);
    cy.contains(`Accept all`).should(`not.exist`);
    cy.contains(`Submit`);
  });

  it(`redirects old single-request URLs to batch UI`, () => {
    cy.interceptPql(`GetBatchUnlockRequestData`, {
      requests: [makeRequest({ id: `req-1`, domain: `example.com` })],
      keychains: [keychain],
    });
    cy.visit(`/children/child-1/unlock-requests/some-request-id`);
    cy.location(`pathname`).should(`eq`, `/children/child-1/unlock-requests`);
  });

  it(`redirects top-level /unlock-requests to dashboard`, () => {
    cy.interceptPql(`DashboardWidgets_v2`, {
      children: [],
      childActivitySummaries: [],
      unlockRequests: [],
      recentScreenshots: [],
      numParentNotifications: 0,
      pendingIOSDevices: [],
    });
    cy.visit(`/unlock-requests`);
    cy.location(`pathname`).should(`eq`, `/`);
  });

  it(`naughty domains default to deny or undecided`, () => {
    cy.interceptPql(`GetBatchUnlockRequestData`, {
      requests: [
        makeRequest({ id: `req-1`, domain: `youtube.com`, url: `https://youtube.com` }),
        makeRequest({
          id: `req-2`,
          domain: `khanacademy.org`,
          url: `https://khanacademy.org`,
        }),
      ],
      keychains: [keychain],
    });
    cy.visit(`/children/child-1/unlock-requests`);
    cy.contains(`Submit`).click();
    cy.wait(`@HandleUnlockRequests`)
      .its(`request.body`)
      .should((body) => {
        const ytDecision = body.decisions.find((d: any) => d.unlockRequestId === `req-1`);
        expect(ytDecision.status).to.eq(`rejected`);
        const kaDecision = body.decisions.find((d: any) => d.unlockRequestId === `req-2`);
        expect(kaDecision.status).to.eq(`accepted`);
      });
  });

  it(`handles API error on load`, () => {
    cy.forcePqlErr(`GetBatchUnlockRequestData`, { type: `serverError` });
    cy.visit(`/children/child-1/unlock-requests`);
    cy.contains(`try again`);
  });
});
