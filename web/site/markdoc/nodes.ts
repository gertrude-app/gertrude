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
  link: {
    ...markdocNodes.link,
    transform(node, config) {
      const attributes = node.transformAttributes(config);
      const children = node.transformChildren(config);
      if (!isOutbound(String(attributes[`href`] ?? ``))) {
        return new Tag(`a`, attributes, children);
      }
      return new Tag(`a`, { ...attributes, rel: `nofollow noopener` }, children);
    },
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

const FOLLOWED_HOSTS = [
  `gertrude.app`,
  `techlockdown.com`,
  `pluckyfilter.com`,
  `pluckeye.net`,
];

function isOutbound(href: string): boolean {
  if (!/^https?:\/\//i.test(href)) return false;
  try {
    const { hostname } = new URL(href);
    return !FOLLOWED_HOSTS.some(
      (host) => hostname === host || hostname.endsWith(`.${host}`),
    );
  } catch {
    return false;
  }
}

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
