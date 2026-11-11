'use client';

import React from 'react';
import HomeAppScreenshots from '@/components/home/HomeAppScreenshots';

const screens = [
  {
    id: `shows`,
    title: `A podcast library of their own.`,
    description: `Every show you’ve added, with new episodes ready when they are.`,
    alt: `Gertrude Podcasts library with approved podcasts and LibriVox audiobooks`,
  },
  {
    id: `show-details`,
    title: `Every episode, ready to play.`,
    description: `Browse episodes, download for later, or jump straight into the latest.`,
    alt: `Gertrude Podcasts show details for New Rustacean, with episodes and a Play Latest button`,
  },
  {
    id: `pin`,
    title: `Your PIN for new shows.`,
    description: `Searching for or adding a podcast always takes your six-digit PIN.`,
    alt: `Gertrude Podcasts six-digit PIN entry screen protecting access to new shows`,
  },
];

const HomePodcastsScreenshots: React.FC<{
  isDark: boolean;
  children: React.ReactNode;
}> = ({ isDark, children }) => (
  <HomeAppScreenshots
    isDark={isDark}
    label="Gertrude Podcasts app screenshots"
    backgroundImage="/home/music-screenshots/background.webp"
    screens={screens.map((screen) => ({
      ...screen,
      src: `/home/podcasts-screenshots/${screen.id}-1350.webp`,
      srcSet: `/home/podcasts-screenshots/${screen.id}-810.webp 810w, /home/podcasts-screenshots/${screen.id}-1350.webp 1350w`,
    }))}
  >
    {children}
  </HomeAppScreenshots>
);

export default HomePodcastsScreenshots;
