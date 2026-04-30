import type { SharedKey, UnlockRequest, UnlockRequestCreateKeyData } from '@dash/types';
import * as domain from './domain';

export function keyForUnlockRequest(request: UnlockRequestCreateKeyData): SharedKey {
  let scope: SharedKey[`scope`] = { type: `webBrowsers` };
  let type: `domain` | `ipAddress` | `anySubdomain` = `domain`;
  let value = ``;

  if (request.url && !request.domain) {
    value = urlHostname(request.url) ?? ``;
  } else if (request.domain) {
    value = request.domain;
  } else if (request.ipAddress) {
    type = `ipAddress`;
    value = request.ipAddress;
  }

  if (!request.appCategories.includes(`browser`)) {
    if (request.appSlug) {
      scope = {
        type: `single`,
        single: { type: `identifiedAppSlug`, identifiedAppSlug: request.appSlug },
      };
    } else {
      scope = {
        type: `single`,
        single: { type: `bundleId`, bundleId: request.appBundleId ?? `` },
      };
    }
  }

  if (type === `ipAddress`) {
    return { type, ipAddress: value, scope };
  }

  const registrable = domain.registrable(value);
  if (!registrable || UNSAFE_DOMAINS.includes(registrable)) {
    return { type: `domain`, domain: value, scope };
  } else {
    return { type: `anySubdomain`, domain: registrable, scope };
  }
}

export type RequestGroup = {
  representative: UnlockRequest;
  duplicateIds: UUID[];
  allRequests: UnlockRequest[];
  key: SharedKey;
};

export type AddressType = `standard` | `strict`;

export function defaultAddressType(key: SharedKey): AddressType {
  return key.type === `anySubdomain` ? `standard` : `strict`;
}

export function hasDomainScope(key: SharedKey): boolean {
  return key.type === `domain` || key.type === `anySubdomain`;
}

export function originalHost(
  request: UnlockRequestCreateKeyData | UnlockRequest,
): string | null {
  if (request.domain) return request.domain;
  if (request.url) return urlHostname(request.url);
  return null;
}

function urlHostname(url: string): string | null {
  try {
    return new URL(url).hostname;
  } catch {
    return null;
  }
}

export function adjustKeyAddressType(
  baseKey: SharedKey,
  addressType: AddressType,
  request: UnlockRequestCreateKeyData | UnlockRequest,
): SharedKey {
  if (!hasDomainScope(baseKey)) return baseKey;
  if (addressType === defaultAddressType(baseKey)) return baseKey;
  if (addressType === `strict` && baseKey.type === `anySubdomain`) {
    const host = originalHost(request) ?? baseKey.domain;
    return { ...baseKey, type: `domain`, domain: host };
  }
  if (addressType === `standard` && baseKey.type === `domain`) {
    return { ...baseKey, type: `anySubdomain` };
  }
  return baseKey;
}

export function keyIdentity(key: SharedKey): string {
  const scope = scopeIdentity(key.scope);
  switch (key.type) {
    case `anySubdomain`:
      return `anySubdomain:${key.domain}:${scope}`;
    case `domain`:
      return `domain:${key.domain}:${scope}`;
    case `ipAddress`:
      return `ipAddress:${key.ipAddress}:${scope}`;
    case `domainRegex`:
      return `domainRegex:${key.pattern}:${scope}`;
    case `skeleton`:
      return `skeleton:${scope}`;
    case `path`:
      return `path:${key.path}:${scope}`;
  }
}

function scopeIdentity(scope: SharedKey[`scope`]): string {
  switch (scope.type) {
    case `unrestricted`:
      return `unrestricted`;
    case `webBrowsers`:
      return `browsers`;
    case `single`:
      return scope.single.type === `identifiedAppSlug`
        ? `slug:${scope.single.identifiedAppSlug}`
        : `bundle:${scope.single.bundleId}`;
    case `bundleId`:
      return `bundle:${scope.bundleId}`;
    case `identifiedAppSlug`:
      return `slug:${scope.identifiedAppSlug}`;
  }
}

export function groupRequestsByKey(requests: UnlockRequest[]): RequestGroup[] {
  const groups = new Map<string, { key: SharedKey; requests: UnlockRequest[] }>();
  for (const request of requests) {
    const key = keyForUnlockRequest(request);
    const id = keyIdentity(key);
    const existing = groups.get(id);
    if (existing) {
      existing.requests.push(request);
    } else {
      groups.set(id, { key, requests: [request] });
    }
  }

  return Array.from(groups.values()).map(({ key, requests: grouped }) => {
    const sorted = [...grouped].sort((a, b) => {
      const aHasComment = !!a.requestComment;
      const bHasComment = !!b.requestComment;
      if (aHasComment !== bHasComment) return aHasComment ? -1 : 1;
      return new Date(b.createdAt).getTime() - new Date(a.createdAt).getTime();
    });
    const representative = sorted[0] as UnlockRequest;
    return {
      representative,
      duplicateIds: sorted.slice(1).map((r) => r.id),
      allRequests: sorted,
      key,
    };
  });
}

export const UNSAFE_DOMAINS = [
  `google.com`,
  `facebook.com`,
  `twitter.com`,
  `wikipedia.org`,
  `youtube.com`,
  `cloudfront.net`,
  `amazonaws.com`,
  `herokuapp.com`,
  `netlify.app`,
  `pages.dev`,
  `googleusercontent.com`,
  `vercel.app`,
  `github.io`,
  `firebaseapp.com`,
  `web.app`,
  `appspot.com`,
  `azurewebsites.net`,
  `fly.dev`,
  `railway.app`,
  `replit.dev`,
  `akamaized.net`,
  `fastly.net`,
  `azureedge.net`,
  `workers.dev`,
  `r2.dev`,
  `blogspot.com`,
  `wordpress.com`,
  `tumblr.com`,
];

export type NaughtyLevel = `deny` | `undecided`;

export const NAUGHTY_DOMAINS: Record<string, { level: NaughtyLevel; reason: string }> = {
  'google.com': { level: `deny`, reason: `Broad access to all Google services` },
  'youtube.com': { level: `deny`, reason: `Unmoderated video content` },
  'facebook.com': { level: `deny`, reason: `Social media with messaging` },
  'twitter.com': { level: `deny`, reason: `Social media with unmoderated content` },
  'x.com': { level: `deny`, reason: `Social media with unmoderated content` },
  'instagram.com': { level: `deny`, reason: `Social media with messaging` },
  'tiktok.com': { level: `deny`, reason: `Unmoderated video content` },
  'snapchat.com': { level: `deny`, reason: `Social media with disappearing messages` },
  'reddit.com': { level: `deny`, reason: `Unmoderated user-generated content` },
  'discord.com': { level: `deny`, reason: `Chat platform with unmoderated servers` },
  'twitch.tv': { level: `deny`, reason: `Livestreaming with unmoderated content` },
  'pinterest.com': { level: `deny`, reason: `Image search with unmoderated content` },
  'tumblr.com': { level: `deny`, reason: `Blogging platform with adult content` },
  'wikipedia.org': { level: `deny`, reason: `Contains explicit/adult content` },
  'bing.com': { level: `deny`, reason: `Search engine with image search` },
  'duckduckgo.com': { level: `deny`, reason: `Search engine with image search` },
  'telegram.org': { level: `deny`, reason: `Messaging with unmoderated channels` },
  'whatsapp.com': { level: `deny`, reason: `Messaging platform` },
  'signal.org': { level: `deny`, reason: `Messaging platform` },
  'omegle.com': { level: `deny`, reason: `Anonymous video chat with strangers` },
  'chatroulette.com': { level: `deny`, reason: `Anonymous video chat with strangers` },
  'perplexity.ai': { level: `undecided`, reason: `AI search with unrestricted results` },
  'chatgpt.com': { level: `deny`, reason: `AI chatbot with unrestricted responses` },
  'claude.ai': { level: `deny`, reason: `AI chatbot with unrestricted responses` },
  'copilot.microsoft.com': {
    level: `deny`,
    reason: `AI chatbot with unrestricted responses`,
  },
  'grok.com': { level: `deny`, reason: `AI chatbot with unrestricted responses` },
  'poe.com': { level: `deny`, reason: `AI chatbot with unrestricted responses` },
  'openai.com': { level: `undecided`, reason: `AI chatbot with unrestricted responses` },
  'blogspot.com': { level: `undecided`, reason: `Blogging platform with mixed content` },
  'wordpress.com': { level: `undecided`, reason: `Blogging platform with mixed content` },
  'medium.com': { level: `undecided`, reason: `Blogging platform with mixed content` },
  'imgur.com': { level: `undecided`, reason: `Image hosting with unmoderated content` },
  'crazygames.com': { level: `undecided`, reason: `Browser gaming portal with chat` },
  'amazon.com': { level: `undecided`, reason: `Shopping and streaming platform` },
  'netflix.com': { level: `deny`, reason: `Streaming platform` },
  'spotify.com': { level: `deny`, reason: `Streaming with explicit content` },
  'roblox.com': { level: `undecided`, reason: `Gaming platform with in-game chat` },
  'gmail.com': { level: `undecided`, reason: `Full email access` },
  'steampowered.com': { level: `deny`, reason: `Gaming platform with community chat` },
  'steamcommunity.com': {
    level: `deny`,
    reason: `Gaming community with unmoderated content`,
  },
  'steam.tv': { level: `deny`, reason: `Gaming livestreaming platform` },
  'epicgames.com': { level: `deny`, reason: `Gaming platform with social features` },
  'discord.gg': { level: `deny`, reason: `Chat platform with unmoderated servers` },
  'discordapp.net': { level: `deny`, reason: `Chat platform with unmoderated servers` },
  'discordapp.com': { level: `deny`, reason: `Chat platform with unmoderated servers` },
  'discord.media': { level: `deny`, reason: `Chat platform with unmoderated servers` },
  'doubleclick.net': { level: `deny`, reason: `Ad/tracking network` },
  'googleadservices.com': { level: `deny`, reason: `Ad/tracking network` },
  'googlesyndication.com': { level: `deny`, reason: `Ad/tracking network` },
  'googletagmanager.com': { level: `deny`, reason: `Ad/tracking network` },
  'applovin.com': { level: `deny`, reason: `Ad network` },
  's3.amazonaws.com': {
    level: `deny`,
    reason: `Gives access to all S3 cloud storage`,
  },
  ...Object.fromEntries(
    [
      `us-east-1`,
      `us-east-2`,
      `us-west-1`,
      `us-west-2`,
      `af-south-1`,
      `ap-east-1`,
      `ap-south-1`,
      `ap-south-2`,
      `ap-southeast-1`,
      `ap-southeast-2`,
      `ap-southeast-3`,
      `ap-southeast-4`,
      `ap-northeast-1`,
      `ap-northeast-2`,
      `ap-northeast-3`,
      `ca-central-1`,
      `ca-west-1`,
      `eu-central-1`,
      `eu-central-2`,
      `eu-west-1`,
      `eu-west-2`,
      `eu-west-3`,
      `eu-south-1`,
      `eu-south-2`,
      `eu-north-1`,
      `il-central-1`,
      `me-south-1`,
      `me-central-1`,
      `sa-east-1`,
    ].map((region) => [
      `s3.${region}.amazonaws.com`,
      { level: `deny`, reason: `Gives access to all S3 cloud storage in this region` },
    ]),
  ),
  'storage.googleapis.com': {
    level: `deny`,
    reason: `Gives access to all Google Cloud storage`,
  },
};

export function naughtyInfo(
  requestOrGroup: UnlockRequest | RequestGroup,
): { level: NaughtyLevel; reason: string } | undefined {
  const isGroup = `representative` in requestOrGroup;
  const request = isGroup ? requestOrGroup.representative : requestOrGroup;
  const hostname = request.domain ?? request.url?.split(`/`)[2] ?? ``;
  if (!hostname) return undefined;
  const registrable = domain.registrable(hostname);
  const hostnameMatch = NAUGHTY_DOMAINS[hostname];
  if (hostnameMatch) return hostnameMatch;
  const info = NAUGHTY_DOMAINS[registrable ?? hostname];
  if (!info) return undefined;
  if (isGroup && registrable && hostname !== registrable) {
    const key = requestOrGroup.key;
    if (key.type === `domain`) {
      const prefix = hostname.slice(0, -(registrable.length + 1));
      const depth = prefix.split(`.`).filter(Boolean).length;
      if (depth > 1) return undefined;
      if (prefix !== `www`) {
        return {
          level: `undecided`,
          reason: `Related to ${registrable}`,
        };
      }
    }
  }
  return info;
}
