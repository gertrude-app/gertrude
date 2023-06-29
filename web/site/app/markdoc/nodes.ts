import { nodes } from '@markdoc/markdoc';
import CodeBlock from './CodeBlock';

export default {
  document: {
    render: undefined,
  },
  fence: {
    render: CodeBlock,
    attributes: nodes.fence.attributes,
  },
  th: {
    ...nodes.th,
    attributes: {
      ...nodes.th.attributes,
      scope: {
        type: String,
        default: `col`,
      },
    },
  },
};
