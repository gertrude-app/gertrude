export function signupAttribution(
  search: string,
  cookies: string,
): {
  gclid?: string;
  abTestVariant?: string;
  referralCode?: string;
} {
  const params = new URLSearchParams(search);
  const cookieValues = new Map(
    cookies.split(`;`).map((cookie) => {
      const separator = cookie.indexOf(`=`);
      return [cookie.slice(0, separator).trim(), cookie.slice(separator + 1)] as const;
    }),
  );
  return {
    gclid: cookieValues.get(`gclid`),
    abTestVariant: params.get(`v`) ?? cookieValues.get(`ab_variant`),
    referralCode: params.get(`ref`) ?? cookieValues.get(`referral_code`),
  };
}
