import { nodes as markdocNodes } from '@markdoc/markdoc';
import type { Config } from '@markdoc/markdoc';

const nodes: Config[`nodes`] = {
  document: {
    render: undefined,
  },
  fence: {
    render: `CodeBlock`,
    attributes: markdocNodes.fence.attributes,
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
