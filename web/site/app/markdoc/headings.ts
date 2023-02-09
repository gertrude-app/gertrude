import { slugifyWithCounter } from '@sindresorhus/slugify';

export type Node = {
  name: string;
  attributes: { id?: string };
  children?: Node[];
};

export type MarkDoc = {
  frontmatter: {
    title: string;
    description: string;
    image?: string;
    pageTitle: string;
  };
  content: Array<Node | string>;
};

type Section = {
  title: string;
  id?: string;
  children?: Section[];
};

export function collectHeadings(
  nodes: Array<Node | string>,
  slugify = slugifyWithCounter(),
): Section[] {
  const sections: Array<Section> = [];

  for (const node of nodes) {
    if (typeof node === `string`) {
      continue;
    }
    if (node.name === `h2` || node.name === `h3`) {
      const title = getNodeText(node);
      if (title) {
        const id = slugify(title);
        node.attributes.id = id;
        if (node.name === `h3`) {
          if (!sections[sections.length - 1]) {
            throw new Error(
              `Cannot add \`h3\` to table of contents without a preceding \`h2\``,
            );
          }
          sections[sections.length - 1]?.children?.push({
            ...node.attributes,
            title,
          });
        } else {
          sections.push({ ...node.attributes, title, children: [] });
        }
      }
    }

    sections.push(...collectHeadings(node.children ?? [], slugify));
  }

  return sections;
}

function getNodeText(node: Node): string {
  let text = ``;
  for (const child of node.children ?? []) {
    if (typeof child === `string`) {
      text += child;
    }
    text += getNodeText(child);
  }
  return text;
}
