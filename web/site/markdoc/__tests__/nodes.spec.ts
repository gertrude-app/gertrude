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

function render(markdown: string): string {
  const content = Markdoc.transform(Markdoc.parse(markdown), { nodes });
  return Markdoc.renderers.html(content);
}
