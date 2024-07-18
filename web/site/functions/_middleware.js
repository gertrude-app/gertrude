// @ts-check

/**
 * @typedef PagesFunction
 * @prop {Request} request
 * @prop {(input?: Request | string, init?: RequestInit) => Promise<Response>} next
 * @prop {{ ASSETS: { fetch: typeof fetch } }} env
 */

/**
 * @param {PagesFunction} props
 * @returns {Promise<Response>}
 */
export const onRequest = async ({ request, next, env }) => {
  const url = new URL(request.url);
  const altPath = alternatePath(url.pathname);
  const cookie = request.headers.get(`cookie`);
  const cookieCohort = getCohort(cookie);
  if (!altPath || cookieCohort === `new_site`) {
    return next();
  }

  if (cookieCohort === `old_site`) {
    url.pathname = altPath;
    return env.ASSETS.fetch(url);
  }

  /** @type {'new_site' | 'old_site'} */
  let cohort = `new_site`;
  if (Math.random() < 0.5) {
    cohort = `old_site`;
    url.pathname = altPath;
  }

  const asset = await env.ASSETS.fetch(url);
  const response = new Response(asset.body, asset);
  response.headers.append(`Set-Cookie`, `ab_variant=${cohort}; path=/; max-age=1209600`);
  return response;
};

/**
 * @param {string | null} cookie
 * @returns {'old_site' | 'new_site' | undefined}
 */
function getCohort(cookie) {
  if (cookie?.includes(`ab_variant=old_site`)) {
    return `old_site`;
  } else if (cookie?.includes(`ab_variant=new_site`)) {
    return `new_site`;
  }
  return undefined;
}

/**
 * @param {string} path
 * @returns {string | undefined}
 */
function alternatePath(path) {
  switch (path) {
    case `/`:
      return `/old`;
    case `/contact`:
      return `/old/contact`;
    case `/download`:
      return `/old/download`;
    default:
      return undefined;
  }
}
