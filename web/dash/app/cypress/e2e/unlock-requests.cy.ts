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

  function appRequest(override: Partial<UnlockRequest> = {}): UnlockRequest {
    return makeRequest({
      appCategories: [], // non-browser => app-scoped
      appName: `Unity Hub`,
      appSlug: `unity-hub`,
      appBundleId: `com.unity3d.unityhub`,
      url: undefined,
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
    cy.interceptPql(`DashboardWidgets_v3`, {
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

  it(`fans out merged subdomain requests when toggled to strict`, () => {
    cy.interceptPql(`GetBatchUnlockRequestData`, {
      requests: [
        makeRequest({
          id: `req-images`,
          domain: `images.foobar.com`,
          url: `https://images.foobar.com/cat.jpg`,
          createdAt: `2026-04-30T12:00:00.000Z`,
        }),
        makeRequest({
          id: `req-cdn`,
          domain: `cdn.foobar.com`,
          url: `https://cdn.foobar.com/lib.js`,
          createdAt: `2026-04-30T11:00:00.000Z`,
        }),
      ],
      keychains: [keychain],
    });
    cy.visit(`/children/child-1/unlock-requests`);
    cy.contains(`foobar.com`);
    cy.testId(`row-edit-toggle`).filter(`:visible`).click();
    cy.testId(`strict-button`).filter(`:visible`).click();
    cy.contains(`Submit`).click();
    cy.wait(`@HandleUnlockRequests`)
      .its(`request.body`)
      .should((body) => {
        expect(body.duplicateRequestIds).to.deep.eq([]);
        expect(body.decisions).to.have.length(2);
        const byId: Record<string, any> = {};
        for (const d of body.decisions) byId[d.unlockRequestId] = d;
        expect(Object.keys(byId).sort()).to.deep.eq([`req-cdn`, `req-images`]);
        expect(byId[`req-images`].status).to.eq(`accepted`);
        expect(byId[`req-cdn`].status).to.eq(`accepted`);
        expect(byId[`req-images`].key.key).to.deep.eq({
          type: `domain`,
          domain: `images.foobar.com`,
          scope: { type: `webBrowsers` },
        });
        expect(byId[`req-cdn`].key.key).to.deep.eq({
          type: `domain`,
          domain: `cdn.foobar.com`,
          scope: { type: `webBrowsers` },
        });
        expect(byId[`req-images`].key.keychainId).to.eq(byId[`req-cdn`].key.keychainId);
        expect(byId[`req-images`].key.comment).to.eq(byId[`req-cdn`].key.comment);
      });
  });

  it(`handles API error on load`, () => {
    cy.forcePqlErr(`GetBatchUnlockRequestData`, { type: `serverError` });
    cy.visit(`/children/child-1/unlock-requests`);
    cy.contains(`try again`);
  });

  it(`collapses one app's many hosts into a single app row`, () => {
    cy.interceptPql(`GetBatchUnlockRequestData`, {
      requests: [
        appRequest({ id: `u1`, domain: `config.unity3d.com` }),
        appRequest({ id: `u2`, domain: `api.unity.com` }),
      ],
      keychains: [keychain],
    });
    cy.visit(`/children/child-1/unlock-requests`);
    cy.contains(`Unity Hub`);
    cy.contains(`2 addresses requested`); // whack-a-mole collapsed to one row
  });

  it(`grants a whole app: emits grantAppScope decisions with no key`, () => {
    cy.interceptPql(`GetBatchUnlockRequestData`, {
      requests: [
        appRequest({ id: `u1`, domain: `config.unity3d.com` }),
        appRequest({ id: `u2`, domain: `api.unity.com` }),
      ],
      keychains: [keychain],
    });
    cy.visit(`/children/child-1/unlock-requests`); // nameable app defaults to "Allow app"
    cy.contains(`Submit`).click();
    cy.wait(`@HandleUnlockRequests`)
      .its(`request.body`)
      .should((body) => {
        expect(body.decisions).to.have.length(2); // one per host request
        for (const d of body.decisions) {
          expect(d.status).to.eq(`accepted`);
          expect(d.grantAppScope).to.deep.eq({
            type: `identifiedAppSlug`,
            identifiedAppSlug: `unity-hub`,
          });
          expect(d.key).to.eq(undefined); // grant path writes no keychain key
        }
      });
  });

  it(`allow-addresses on an app: emits app-scoped keychain keys, no grant`, () => {
    cy.interceptPql(`GetBatchUnlockRequestData`, {
      requests: [
        appRequest({ id: `u1`, domain: `config.unity3d.com` }),
        appRequest({ id: `u2`, domain: `api.unity.com` }),
      ],
      keychains: [keychain],
    });
    cy.visit(`/children/child-1/unlock-requests`);
    cy.contains(`Unity Hub`)
      .closest(`tr, [class*="border"]`)
      .contains(`Allow 2 addresses`)
      .click();
    cy.contains(`Submit`).click();
    cy.wait(`@HandleUnlockRequests`)
      .its(`request.body`)
      .should((body) => {
        expect(body.decisions).to.have.length(2);
        for (const d of body.decisions) {
          expect(d.status).to.eq(`accepted`);
          expect(d.grantAppScope).to.eq(undefined);
          expect(d.key.keychainId).to.eq(`keychain-1`); // into the chosen keychain
          expect(d.key.key.scope).to.deep.eq({
            type: `single`,
            single: { type: `identifiedAppSlug`, identifiedAppSlug: `unity-hub` },
          });
        }
      });
  });

  it(`denies a whole app: rejects every host request`, () => {
    cy.interceptPql(`GetBatchUnlockRequestData`, {
      requests: [
        appRequest({ id: `u1`, domain: `config.unity3d.com` }),
        appRequest({ id: `u2`, domain: `api.unity.com` }),
      ],
      keychains: [keychain],
    });
    cy.visit(`/children/child-1/unlock-requests`);
    cy.contains(`Unity Hub`).closest(`tr, [class*="border"]`).contains(`Deny`).click();
    cy.contains(`Submit`).click();
    cy.wait(`@HandleUnlockRequests`)
      .its(`request.body`)
      .should((body) => {
        expect(body.decisions).to.have.length(2);
        for (const d of body.decisions) expect(d.status).to.eq(`rejected`);
      });
  });

  it(`unidentified app defaults to allow-addresses (key, not grant)`, () => {
    cy.interceptPql(`GetBatchUnlockRequestData`, {
      requests: [
        appRequest({
          id: `w1`,
          appName: undefined, // no display name => "Allow addresses" default
          appSlug: undefined,
          appBundleId: `4P553833NY.com.gaijinent.WarThunder`,
          domain: undefined,
          ipAddress: `99.81.103.55`,
        }),
      ],
      keychains: [keychain],
    });
    cy.visit(`/children/child-1/unlock-requests`);
    cy.contains(`Submit`).click();
    cy.wait(`@HandleUnlockRequests`)
      .its(`request.body`)
      .should((body) => {
        expect(body.decisions).to.have.length(1);
        const [d] = body.decisions;
        expect(d.status).to.eq(`accepted`);
        expect(d.grantAppScope).to.eq(undefined);
        expect(d.key).to.not.eq(undefined); // approved as a keychain key
      });
  });
});
