import type { Config } from '@markdoc/markdoc';
import CodeBlock from './CodeBlock';
import nodes from './nodes';
import tags from './tags';
import ArticleImage from '@/components/articles/ArticleImage';
import Callout from '@/components/articles/Callout';
import ClickToReveal from '@/components/articles/ClickToReveal';
import EmbeddedVideo from '@/components/articles/EmbeddedVideo';
import Figure from '@/components/articles/Figure';
import IOSVersionPicker from '@/components/articles/IOSVersionPicker';
import NewFeatureBadge from '@/components/articles/NewFeatureBadge';
import { QuickLink, QuickLinks } from '@/components/articles/QuickLinks';
import ReferralShareLink from '@/components/articles/ReferralShareLink';

export const config: Config = {
  nodes,
  tags,
};

export const components = {
  ArticleImage: ArticleImage,
  Callout: Callout,
  ClickToReveal: ClickToReveal,
  CodeBlock: CodeBlock,
  EmbeddedVideo: EmbeddedVideo,
  Figure: Figure,
  IOSVersionPicker: IOSVersionPicker,
  NewFeatureBadge: NewFeatureBadge,
  QuickLink: QuickLink,
  QuickLinks: QuickLinks,
  ReferralShareLink: ReferralShareLink,
};
