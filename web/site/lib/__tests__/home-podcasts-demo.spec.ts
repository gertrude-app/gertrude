import { describe, expect, it } from 'vitest';
import {
  finalPodcastDemoFrame,
  initialAllowedShowIds,
  initialPodcastDemoFrame,
  podcastCatalogIds,
  podcastDemoFrames,
  podcastDemoPin,
  podcastFlightDuration,
  podcastFlightStagger,
  podcastShows,
  selectedPodcastShowIds,
} from '../home-podcasts-demo';

describe(`homepage podcast demonstration`, () => {
  it(`enters all six PIN digits before revealing the catalog`, () => {
    expect(initialPodcastDemoFrame).toEqual({
      at: 0,
      phase: `pin`,
      pinDigits: 0,
      selectedCount: 0,
    });
    expect(podcastDemoPin).toHaveLength(6);
    const pinFrames = podcastDemoFrames.filter((frame) => frame.phase === `pin`);
    expect(pinFrames.map((frame) => frame.pinDigits)).toEqual([0, 1, 2, 3, 4, 5, 6]);
    const completedPin = pinFrames[pinFrames.length - 1]!;
    for (const frame of podcastDemoFrames.filter((frame) => frame.phase !== `pin`)) {
      expect(frame.pinDigits).toBe(6);
      expect(frame.at).toBeGreaterThan(completedPin.at);
    }
  });

  it(`selects new shows from the catalog, not shows already in the allowed library`, () => {
    expect(podcastCatalogIds).toHaveLength(9);
    expect(new Set(podcastCatalogIds).size).toBe(podcastCatalogIds.length);
    expect(new Set(selectedPodcastShowIds).size).toBe(2);
    for (const id of selectedPodcastShowIds) {
      expect(podcastCatalogIds).toContain(id);
      expect(initialAllowedShowIds).not.toContain(id);
    }
    expect(new Set([...podcastCatalogIds, ...initialAllowedShowIds])).toEqual(
      new Set(Object.keys(podcastShows)),
    );
  });

  it(`selects shows one at a time after unlocking the catalog`, () => {
    const catalog = podcastDemoFrames.find((frame) => frame.phase === `catalog`)!;
    const selections = podcastDemoFrames.filter((frame) => frame.phase === `selecting`);
    expect(selections.map((frame) => frame.selectedCount)).toEqual([1, 2]);
    for (const frame of selections) expect(frame.at).toBeGreaterThan(catalog.at);
  });

  it(`allows all cover flights to finish before settling`, () => {
    const transfer = podcastDemoFrames.find((frame) => frame.phase === `transferring`)!;
    expect(transfer.selectedCount).toBe(selectedPodcastShowIds.length);
    expect(finalPodcastDemoFrame.at - transfer.at).toBeGreaterThan(
      podcastFlightDuration + (selectedPodcastShowIds.length - 1) * podcastFlightStagger,
    );
    expect(finalPodcastDemoFrame.phase).toBe(`settled`);
    expect(finalPodcastDemoFrame.selectedCount).toBe(selectedPodcastShowIds.length);
  });

  it(`schedules a short, strictly ordered, single-pass sequence`, () => {
    for (let index = 1; index < podcastDemoFrames.length; index++) {
      expect(podcastDemoFrames[index]!.at).toBeGreaterThan(
        podcastDemoFrames[index - 1]!.at,
      );
    }
    expect(finalPodcastDemoFrame.at).toBeLessThanOrEqual(8000);
  });
});
