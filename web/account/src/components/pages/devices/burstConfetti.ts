import confetti from 'canvas-confetti';

export const burstConfetti = (): void => {
  for (const [x, angle] of [
    [0.02, 65],
    [0.98, 115],
  ] as const) {
    void confetti({
      particleCount: 100,
      angle,
      spread: 55,
      startVelocity: 68,
      gravity: 0.85,
      scalar: 0.9,
      origin: { x, y: 0.98 },
      colors: [`#8b5cf6`, `#c4b4ff`, `#d946ef`, `#fbbf24`, `#38bdf8`],
      disableForReducedMotion: true,
    });
  }
};
