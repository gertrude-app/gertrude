import { describe, expect, test } from 'vitest';
import { signupAttribution } from '../signup';

describe(`signup attribution`, () => {
  test(`prefers query referral and variant over cookies`, () => {
    expect(
      signupAttribution(
        `?ref=QUERY-CODE&v=new_site`,
        `referral_code=COOKIE-CODE; ab_variant=old_site; gclid=ad-click`,
      ),
    ).toEqual({
      referralCode: `QUERY-CODE`,
      abTestVariant: `new_site`,
      gclid: `ad-click`,
    });
  });

  test(`uses cookies when query attribution is absent`, () => {
    expect(
      signupAttribution(
        ``,
        `other=value; referral_code=PARENT-CODE; ab_variant=new_site; gclid=click=123`,
      ),
    ).toEqual({
      referralCode: `PARENT-CODE`,
      abTestVariant: `new_site`,
      gclid: `click=123`,
    });
  });

  test(`does not invent attribution when there is none`, () => {
    expect(signupAttribution(`?unrelated=value`, ``)).toEqual({
      referralCode: undefined,
      abTestVariant: undefined,
      gclid: undefined,
    });
  });

  test(`decodes query values without matching similarly named cookies`, () => {
    expect(
      signupAttribution(
        `?ref=PARENT%2DCODE`,
        `not_gclid=wrong; not_referral_code=wrong; not_ab_variant=wrong`,
      ),
    ).toEqual({
      referralCode: `PARENT-CODE`,
      abTestVariant: undefined,
      gclid: undefined,
    });
  });
});
