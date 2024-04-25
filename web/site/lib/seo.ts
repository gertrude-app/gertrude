import type { Metadata } from 'next';

export function createMetadata(
  title: string,
  description: string,
  image?: string,
): Metadata {
  return {
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
