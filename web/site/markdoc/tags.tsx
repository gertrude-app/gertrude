import type { Config } from '@markdoc/markdoc';

const tags: Config['tags'] = {
  callout: {
    attributes: {
      alt: { type: Boolean },
      title: { type: String },
      type: {
        type: String,
        default: `note`,
        matches: [`note`, `warning`],
        errorLevel: `critical`,
      },
    },
    render: `Callout`,
  },
  image: {
    selfClosing: true,
    attributes: {
      src: { type: String },
      caption: { type: String },
      alt: { type: String },
      small: { type: Boolean },
    },
    render: `ArticleImage`,
  },
  video: {
    selfClosing: true,
    attributes: {
      videoId: { type: String },
      title: { type: String },
    },
    render: `EmbeddedVideo`,
  },
  figure: {
    selfClosing: true,
    attributes: {
      src: { type: String },
      alt: { type: String },
      caption: { type: String },
    },
    render: `Figure`,
  },
  'click-to-reveal': {
    selfClosing: false,
    attributes: {
      title: { type: String },
    },
    render: `ClickToReveal`,
  },
  'article-feedback-form': {
    attributes: {
      name: { type: String },
      lang: {
        type: String,
        default: `en`,
        matches: [`en`, `es`],
        errorLevel: `critical`,
      },
    },
    render: `ArticleFeedbackForm`,
  },
  'quick-links': {
    render: `QuickLinks`,
  },
  'quick-link': {
    selfClosing: true,
    render: `QuickLink`,
    attributes: {
      title: { type: String },
      description: { type: String },
      icon: { type: String },
      href: { type: String },
    },
  },
};

export default tags;
