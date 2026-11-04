import { podcastArtwork } from './home-podcast-artwork';

export type PodcastDemoPhase =
  `pin` | `catalog` | `selecting` | `transferring` | `settled`;

export interface PodcastDemoFrame {
  at: number;
  phase: PodcastDemoPhase;
  pinDigits: number;
  selectedCount: number;
}

export const podcastShows = podcastArtwork;

export type PodcastShowId = keyof typeof podcastShows;

export const initialAllowedShowIds = [
  `beatrix-potter`,
  `this-week-in-linux`,
] as const satisfies readonly PodcastShowId[];
export const selectedPodcastShowIds = [
  `materialism`,
  `velveteen-rabbit`,
] as const satisfies readonly PodcastShowId[];
export const podcastCatalogIds = [
  `new-rustacean`,
  `materialism`,
  `frets`,
  `hardware-addicts`,
  `web-but-green`,
  `sudo-show`,
  `velveteen-rabbit`,
  `linux-out-loud`,
  `destination-linux`,
] as const satisfies readonly PodcastShowId[];

export const podcastDemoPin = [`4`, `8`, `2`, `6`, `1`, `9`] as const;
export const podcastFlightDuration = 1000;
export const podcastFlightStagger = 180;

export const finalPodcastDemoFrame = {
  at: 7100,
  phase: `settled`,
  pinDigits: 6,
  selectedCount: selectedPodcastShowIds.length,
} as const satisfies PodcastDemoFrame;

export const podcastDemoFrames = [
  { at: 0, phase: `pin`, pinDigits: 0, selectedCount: 0 },
  { at: 900, phase: `pin`, pinDigits: 1, selectedCount: 0 },
  { at: 1160, phase: `pin`, pinDigits: 2, selectedCount: 0 },
  { at: 1420, phase: `pin`, pinDigits: 3, selectedCount: 0 },
  { at: 1680, phase: `pin`, pinDigits: 4, selectedCount: 0 },
  { at: 1940, phase: `pin`, pinDigits: 5, selectedCount: 0 },
  { at: 2200, phase: `pin`, pinDigits: 6, selectedCount: 0 },
  { at: 3000, phase: `catalog`, pinDigits: 6, selectedCount: 0 },
  { at: 4400, phase: `selecting`, pinDigits: 6, selectedCount: 1 },
  { at: 4800, phase: `selecting`, pinDigits: 6, selectedCount: 2 },
  { at: 5500, phase: `transferring`, pinDigits: 6, selectedCount: 2 },
  finalPodcastDemoFrame,
] as const satisfies readonly PodcastDemoFrame[];

export const initialPodcastDemoFrame = podcastDemoFrames[0];
