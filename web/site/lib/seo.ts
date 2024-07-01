import type { Metadata } from 'next';

export function createMetadata(
  title: string,
  description: string,
  image?: string,
): Metadata {
  return {
    metadataBase: metadataBase(),
    title,
    description,
    openGraph: {
      title,
      description,
      images: image
        ? [{ url: image, width: 1200, height: 630, alt: title }]
        : [{ url: `/og-images/main.jpg`, width: 1200, height: 630, alt: title }],
    },
  };
}

export function description(description: string): string {
  if (description.length > 80) {
    return description;
  }
  return `${description}. Protect your kids online with easy-to-use Mac internet filtering, internet blocking, and mac keylogging.`;
}

export function metadataBase(): URL {
  const isNetlify = process.env.NETLIFY !== undefined;
  const context = process.env.CONTEXT;
  switch (true) {
    case isNetlify && context === `production`:
      return new URL(`https://gertrude.app`);
    case isNetlify && context === `dev`:
      return new URL(`http://localhost:3000`);
    case isNetlify &&
      context === `deploy-preview` &&
      process.env.DEPLOY_PRIME_URL !== undefined:
      return new URL(process.env.DEPLOY_PRIME_URL);
    case process.env.NODE_ENV === `development`:
      return new URL(`http://localhost:3000`);
    default:
      return new URL(`https://gertrude.app`);
  }
}
