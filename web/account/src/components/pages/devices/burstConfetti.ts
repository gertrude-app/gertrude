import confetti from 'canvas-confetti';

let activeBurst:
  { canvas: HTMLCanvasElement; fire: ReturnType<typeof confetti.create> } | undefined;

export const burstConfetti = (): void => {
  if (!activeBurst) {
    const canvas = document.createElement(`canvas`);
    canvas.className = `pointer-events-none fixed inset-0 z-[100] h-full w-full transform-gpu`;
    document.body.append(canvas);
    activeBurst = {
      canvas,
      fire: confetti.create(canvas, { resize: true, useWorker: true }),
    };
  }
  const { canvas, fire } = activeBurst;
  const bursts = (
    [
      [0.02, 65],
      [0.98, 115],
    ] as const
  ).map(([x, angle]) =>
    fire({
      particleCount: 100,
      angle,
      spread: 55,
      startVelocity: 68,
      gravity: 0.85,
      scalar: 0.9,
      origin: { x, y: 0.98 },
      colors: [`#8b5cf6`, `#c4b4ff`, `#d946ef`, `#fbbf24`, `#38bdf8`],
      disableForReducedMotion: true,
    }),
  );
  void Promise.all(bursts).then(() => {
    canvas.remove();
    activeBurst = undefined;
  });
};
