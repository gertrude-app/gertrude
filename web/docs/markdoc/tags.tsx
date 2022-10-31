import Callout from '@/components/Callout';
import { QuickLink, QuickLinks } from '@/components/QuickLinks';
import ArticleImage from '@/components/ArticleImage';

const tags = {
  callout: {
    attributes: {
      title: { type: String },
      type: {
        type: String,
        default: `note`,
        matches: [`note`, `warning`],
        errorLevel: `critical`,
      },
    },
    render: Callout,
  },
  image: {
    selfClosing: true,
    attributes: {
      src: { type: String },
      caption: { type: String },
    },
    render: ArticleImage,
  },
  figure: {
    selfClosing: true,
    attributes: {
      src: { type: String },
      alt: { type: String },
      caption: { type: String },
    },
    render: renderFigure,
  },
  'quick-links': {
    render: QuickLinks,
  },
  'quick-link': {
    selfClosing: true,
    render: QuickLink,
    attributes: {
      title: { type: String },
      description: { type: String },
      icon: { type: String },
      href: { type: String },
    },
  },
};

export default tags;

function renderFigure({
  src,
  alt = ``,
  caption,
}: {
  src: string;
  alt?: string;
  caption: string;
}): JSX.Element {
  return (
    <figure>
      <img src={src} alt={alt} />
      <figcaption>{caption}</figcaption>
    </figure>
  );
}
