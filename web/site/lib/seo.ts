import type { Metadata } from 'next';

export function createMetadata(title: string, summary: string, image?: string): Metadata {
  const description = expandDescription(summary);

  return {
    metadataBase: metadataBase(),
    title,
    description,
    openGraph: {
      type: `website`,
      title,
      description,
      images: image
        ? [{ url: image, width: 1200, height: 630, alt: title }]
        : [{ url: `/og-images/main.png`, width: 1200, height: 630, alt: title }],
    },
  };
}

export function description(description: string): string {
  return expandDescription(description);
}

function expandDescription(description: string): string {
  if (description.length > 80) {
    return description;
  }
  return `${description}. Protect your iPhones, iPads, and Macs with super strict filtering, monitoring, and curated content apps.`;
}

function metadataBase(): URL {
  const isCloudflarePages = process.env[`CF_PAGES`] === `1`;
  const branch = process.env[`CF_PAGES_BRANCH`];
  const deployUrl = process.env[`CF_PAGES_URL`];

  switch (true) {
    case isCloudflarePages && branch !== `master` && deployUrl !== undefined:
      return new URL(deployUrl);

    case isCloudflarePages && branch === `master`:
      return new URL(`https://gertrude.app`);

    case process.env.NODE_ENV === `development`:
      return new URL(`http://localhost:3000`);

    default:
      return new URL(`https://gertrude.app`);
  }
}
