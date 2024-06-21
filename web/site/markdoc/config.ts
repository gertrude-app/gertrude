import type { Config } from '@markdoc/markdoc';
import tags from './tags';
import nodes from './nodes';
import CodeBlock from './CodeBlock';
import Callout from '@/components/articles/Callout';
import ArticleImage from '@/components/articles/ArticleImage';
import Figure from '@/components/articles/Figure';
import ClickToReveal from '@/components/articles/ClickToReveal';
import ArticleFeedbackForm from '@/components/articles/ArticleFeedbackForm';
import { QuickLink, QuickLinks } from '@/components/articles/QuickLinks';

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
  Figure: Figure,
  QuickLink: QuickLink,
  QuickLinks: QuickLinks,
};
