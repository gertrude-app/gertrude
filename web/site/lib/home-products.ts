export const homeProducts = {
  mac: {
    href: `/mac`,
    visualSrc: `/home/product-visuals/mac.webp`,
    iconSrc: `/app-icons/gertrude.webp`,
    title: `Gertrude for Mac`,
    description: `Block everything except what you approve, plus activity monitoring.`,
  },
  blocker: {
    href: `/iphone-and-ipad`,
    visualSrc: `/home/product-visuals/blocker.webp`,
    iconSrc: `/app-icons/gertrude.webp`,
    title: `Blocker`,
    description: `Close Screen Time gaps on iPhone and iPad.`,
  },
  music: {
    href: `/music`,
    visualSrc: `/home/product-visuals/music.webp`,
    iconSrc: `/app-icons/music.webp`,
    title: `Music`,
    description: `Parent-approved music, with playlists of their own.`,
  },
  podcasts: {
    href: `/#podcasts`,
    learnMoreHref: `/updates/gertrude-podcasts-launch`,
    visualSrc: `/home/product-visuals/podcasts.webp`,
    iconSrc: `/app-icons/podcasts.webp`,
    title: `Podcasts`,
    description: `Approved shows, with a PIN for new podcasts.`,
  },
} as const;
