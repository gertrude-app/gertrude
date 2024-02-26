import type { Config } from '@markdoc/markdoc';
import Callout from '../components/Callout';
import ArticleImage from '../components/ArticleImage';
import Figure from '../components/Figure';
import ClickToReveal from '../components/ClickToReveal';
import ArticleFeedbackForm from '../components/ArticleFeedbackForm';
import { QuickLink, QuickLinks } from '../components/QuickLinks';
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
