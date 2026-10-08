import { renderToStaticMarkup } from 'react-dom/server';
import { describe, expect, test } from 'vitest';
import Input from '../Input';

describe(`input sizes`, () => {
  test.each([undefined, `medium`, `small`] as const)(
    `size=%s preserves numeric attributes and accessible labeling`,
    (size) => {
      const markup = renderToStaticMarkup(
        <Input
          type="number"
          size={size}
          value="30"
          setValue={() => undefined}
          ariaLabel="Delay for"
          min={1}
          max={90}
        />,
      );
      const input = markup.match(/<input[^>]*>/)?.[0];
      expect(input).toContain(`type="number"`);
      expect(input).toContain(`aria-label="Delay for"`);
      expect(input).toContain(`min="1" max="90"`);
      expect(input).toContain(`value="30"`);
      expect(markup).toContain(size === `small` ? `min-h-[28px]` : `min-h-[36.5px]`);
      expect(input?.includes(`text-xs`)).toBe(size === `small`);
    },
  );

  test.each([undefined, `days`])(
    `small inputs scale prefix, suffix=%s, and action content`,
    (suffix) => {
      const markup = renderToStaticMarkup(
        <Input
          type="text"
          size="small"
          value="30"
          setValue={() => undefined}
          prefix="After"
          suffix={suffix}
          button={{ label: `Apply`, onClick: () => undefined }}
        />,
      );
      expect(markup).toContain(`px-2 text-xs`);
      expect(markup).toContain(`px-1.5`);
      expect(markup).toContain(`<span class="text-xs">Apply</span>`);
      expect(markup.includes(`pr-20`)).toBe(suffix === undefined);
      if (suffix) expect(markup).toContain(`text-xs">days</span>`);
    },
  );

  test(`small inputs preserve disabled and error states`, () => {
    const markup = renderToStaticMarkup(
      <Input
        id="delay"
        type="number"
        size="small"
        value="30"
        setValue={() => undefined}
        label="Delay"
        error="Choose between 1 and 90 days."
        disabled
        button={{ label: `Apply`, onClick: () => undefined }}
      />,
    );
    expect(markup).toContain(`for="delay"`);
    expect(markup).toContain(`aria-invalid="true"`);
    expect(markup).toContain(`aria-describedby="delay-description"`);
    expect(markup).toContain(`id="delay-description"`);
    expect(markup.match(/disabled=""/g)).toHaveLength(2);
  });
});
