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

function metadataBase(): URL {
  const isCloudflarePages = process.env.CF_PAGES === `1`;
  const branch = process.env.CF_PAGES_BRANCH;
  const deployUrl = process.env.CF_PAGES_URL;

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
