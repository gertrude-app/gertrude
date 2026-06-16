import type { Config } from '@markdoc/markdoc';
import CodeBlock from './CodeBlock';
import nodes from './nodes';
import tags from './tags';
import ArticleFeedbackForm from '@/components/articles/ArticleFeedbackForm';
import ArticleImage from '@/components/articles/ArticleImage';
import Callout from '@/components/articles/Callout';
import ClickToReveal from '@/components/articles/ClickToReveal';
import EmbeddedVideo from '@/components/articles/EmbeddedVideo';
import Figure from '@/components/articles/Figure';
import NewFeatureBadge from '@/components/articles/NewFeatureBadge';
import { QuickLink, QuickLinks } from '@/components/articles/QuickLinks';
import ReferralShareLink from '@/components/articles/ReferralShareLink';

export const config: Config = {
  nodes,
  tags,
};

export const components = {
  ArticleFeedbackForm: ArticleFeedbackForm,
  ArticleImage: ArticleImage,
  Callout: Callout,
  ClickToReveal: ClickToReveal,
  CodeBlock: CodeBlock,
  EmbeddedVideo: EmbeddedVideo,
  Figure: Figure,
  NewFeatureBadge: NewFeatureBadge,
  QuickLink: QuickLink,
  QuickLinks: QuickLinks,
  ReferralShareLink: ReferralShareLink,
};
