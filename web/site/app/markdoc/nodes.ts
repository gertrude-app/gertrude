import { nodes as defaultNodes } from '@markdoc/markdoc';

const nodes = {
  document: {
    render: undefined,
  },
  th: {
    ...defaultNodes.th,
    attributes: {
      ...defaultNodes.th.attributes,
      scope: {
        type: String,
        default: `col`,
      },
    },
  },
};

export default nodes;
