import { Tag, nodes as markdocNodes } from '@markdoc/markdoc';
import type { Config, Node } from '@markdoc/markdoc';

const nodes: Config[`nodes`] = {
  document: {
    render: undefined,
  },
  fence: {
    render: `CodeBlock`,
    attributes: markdocNodes.fence.attributes,
  },
  heading: {
    ...markdocNodes.heading,
    transform(node, config) {
      const attributes = node.transformAttributes(config);
      const explicitId = attributes[`id`];
      const generatedId = slugifyHeading(headingText(node));
      return new Tag(
        `h${node.attributes[`level`]}`,
        explicitId || !generatedId ? attributes : { ...attributes, id: generatedId },
        node.transformChildren(config),
      );
    },
  },
  th: {
    ...markdocNodes.th,
    attributes: {
      ...markdocNodes.th.attributes,
      scope: {
        type: String,
        default: `col`,
      },
    },
  },
};

export default nodes;

function headingText(node: Node): string {
  return [...node.walk()]
    .filter((child) => child.type === `text` || child.type === `code`)
    .map((child) => String(child.attributes[`content`] ?? ``))
    .join(``);
}

function slugifyHeading(text: string): string {
  return text
    .normalize(`NFKD`)
    .replace(/[\u0300-\u036f]/g, ``)
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, `-`)
    .replace(/^-+|-+$/g, ``);
}
