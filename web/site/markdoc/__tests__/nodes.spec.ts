import Markdoc from '@markdoc/markdoc';
import { describe, expect, it } from 'vitest';
import nodes from '../nodes';

describe(`heading nodes`, () => {
  it(`generates linkable IDs from heading text`, () => {
    expect(render(`## Narrowing the scope`)).toContain(
      `<h2 id="narrowing-the-scope">Narrowing the scope</h2>`,
    );
  });

  it(`preserves explicit heading IDs`, () => {
    expect(render(`## Existing heading {% id="kept-id" %}`)).toContain(
      `<h2 id="kept-id">Existing heading </h2>`,
    );
  });

  it(`includes formatted text when generating an ID`, () => {
    expect(render(`#### 1. \`.com\` bias`)).toContain(
      `<h4 id="1-com-bias">1. <code>.com</code> bias</h4>`,
    );
  });
});

describe(`link nodes`, () => {
  it(`marks outbound links nofollow so they don't pass link equity`, () => {
    expect(render(`[Bark](https://www.bark.us/blog/google-maps-safety/)`)).toContain(
      `<a href="https://www.bark.us/blog/google-maps-safety/" rel="nofollow noopener">`,
    );
  });

  it(`leaves internal links alone`, () => {
    expect(render(`[our app](/iphone-and-ipad)`)).toContain(
      `<a href="/iphone-and-ipad">`,
    );
  });

  it(`treats our own domains as internal`, () => {
    expect(render(`[dash](https://parents.gertrude.app/login)`)).not.toContain(
      `nofollow`,
    );
  });

  it(`ignores mailto and other non-http schemes`, () => {
    expect(render(`[mail](mailto:support@gertrude.app)`)).not.toContain(`nofollow`);
  });

  it(`passes link equity to allied filtering sites`, () => {
    expect(render(`[tl](https://www.techlockdown.com/articles/x)`)).not.toContain(
      `nofollow`,
    );
    expect(render(`[p](https://pluckyfilter.com/)`)).not.toContain(`nofollow`);
    expect(render(`[pe](https://docs.pluckeye.net/faq)`)).not.toContain(`nofollow`);
  });
});

function render(markdown: string): string {
  const content = Markdoc.transform(Markdoc.parse(markdown), { nodes });
  return Markdoc.renderers.html(content);
}
