import { expect, test } from 'vitest';
import { makeVerificationClient } from './client';

// Typed cross-tier oracle: after the dashboard UI drives the podcasts claim (Cypress), assert the
// backend actually recorded it — through the generated, type-checked PairQL contract rather
// than raw SQL. Contract drift (renamed field, changed shape) breaks this at `tsc` time.
// This is the *oracle*, not the behavior under test; the claim action stays in the real UI.

const code = Number(process.env.ORACLE_CLAIM_CODE ?? `0`);

test(`podcasts claim ${code} resolves to the done step in the backend`, async () => {
  const oracle = makeVerificationClient();
  const data = await oracle.getPodcastsClaimData(code);
  expect(data.resumeStep?.case).toBe(`done`); // claim persisted cross-tier
});
