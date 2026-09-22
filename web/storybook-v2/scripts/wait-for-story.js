export async function waitForStoryToSettle(page) {
  await page.waitForSelector(`#storybook-root`, { state: `attached` });
  await page.waitForFunction(
    () => document.querySelector(`#storybook-root`)?.childNodes.length > 0,
  );
  await page.waitForFunction(async () => {
    await document.fonts?.ready;
    const root = document.querySelector(`#storybook-root`);
    const backgroundSources = new Set();
    for (const element of [root, ...root.querySelectorAll(`*`)]) {
      if (element.getClientRects().length === 0) {
        continue;
      }
      for (const pseudo of [null, `::before`, `::after`]) {
        const style = getComputedStyle(element, pseudo);
        if (pseudo && (style.content === `none` || style.content === `normal`)) {
          continue;
        }
        for (const [, source] of style.backgroundImage.matchAll(
          /url\("((?:\\.|[^"\\])*)"\)/g,
        )) {
          backgroundSources.add(source.replace(/\\(.)/g, `$1`));
        }
      }
    }

    await Promise.all([
      ...Array.from(document.images, (image) => {
        if (image.complete) {
          return undefined;
        }

        return new Promise((resolveImage) => {
          image.addEventListener(`load`, resolveImage, { once: true });
          image.addEventListener(`error`, resolveImage, { once: true });
        });
      }),
      ...Array.from(backgroundSources, async (source) => {
        const image = new Image();
        image.src = source;
        try {
          await image.decode();
        } catch (error) {
          throw new Error(`Could not decode CSS background image: ${source}`, {
            cause: error,
          });
        }
      }),
    ]);
    await new Promise((resolveAnimationFrame) =>
      requestAnimationFrame(() => requestAnimationFrame(resolveAnimationFrame)),
    );
    return true;
  });
}
