import type { Config } from '@markdoc/markdoc';
import Callout from '../components/docs/Callout';
import ArticleImage from '../components/docs/ArticleImage';
import Figure from '../components/docs/Figure';
import ClickToReveal from '../components/docs/ClickToReveal';
import ArticleFeedbackForm from '../components/docs/ArticleFeedbackForm';
import { QuickLink, QuickLinks } from '../components/docs/QuickLinks';
import tags from './tags';
import nodes from './nodes';
import CodeBlock from './CodeBlock';

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
