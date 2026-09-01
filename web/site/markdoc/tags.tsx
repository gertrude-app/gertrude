import type { Config } from '@markdoc/markdoc';

const tags: Config[`tags`] = {
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
      width: { type: Number },
      noBorder: { type: Boolean },
    },
    render: `ArticleImage`,
  },
  video: {
    selfClosing: true,
    attributes: {
      videoId: { type: String },
      title: { type: String },
      description: { type: String },
      uploadDate: { type: String },
      duration: { type: String },
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
  'ios-version-picker': {
    selfClosing: true,
    attributes: {
      current: {
        type: String,
        matches: [`ios-16`, `ios-17`, `ios-18`, `ios-26`],
        errorLevel: `critical`,
      },
    },
    render: `IOSVersionPicker`,
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
  'new-feature': {
    selfClosing: true,
    inline: true,
    render: `NewFeatureBadge`,
  },
  'referral-share-link': {
    selfClosing: true,
    render: `ReferralShareLink`,
  },
};

export default tags;
