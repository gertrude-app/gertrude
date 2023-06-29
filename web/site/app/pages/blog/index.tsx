import { basename } from 'node:path';
import fs from 'node:fs';
import React from 'react';
import { sync as glob } from 'glob';
import Markdoc from '@markdoc/markdoc';
import yaml from 'js-yaml';
import type { GetStaticProps } from 'next';
import DocsLayout from '../../docs/Layout';

interface Post {
  title: string;
  slug: string;
  date: string;
  description: string;
  draft?: boolean;
}

export const getStaticProps: GetStaticProps = async () => {
  const paths = glob(`${process.cwd()}/pages/blog/**/*.md`);
  const posts: Post[] = paths.map((path) => {
    const source = fs.readFileSync(path, `utf8`);
    const ast = Markdoc.parse(source);
    const frontmatter = yaml.load(ast.attributes.frontmatter);
    validateFrontmatter(frontmatter, path);
    const descAst = Markdoc.parse(frontmatter.description);
    const description = Markdoc.renderers.html(Markdoc.transform(descAst));
    return {
      title: frontmatter.title,
      slug: basename(path, `.md`),
      date: frontmatter.date,
      description,
    };
  });

  return {
    props: { posts: posts.filter((post) => !post.draft) },
  };
};

const BlogPosts: React.FC<{ posts: Post[] }> = ({ posts }) => (
  <DocsLayout title="Gertrude Engineering Blog" tableOfContents={[]}>
    {posts
      .sort((a, b) => (a.date < b.date ? 1 : -1))
      .map((post) => (
        <BlogPost key={post.slug} {...post} />
      ))}
  </DocsLayout>
);

const BlogPost: React.FC<Post> = ({ title, slug, date, description }) => (
  <article className="mb-16">
    <div className="flex items-start justify-between">
      <h2 className="m-0">
        <a href={`/blog/${slug}`}>{title}</a>
      </h2>
      <p className="text-white/80 font-bold pl-6 m-0">
        <time dateTime={date}>{new Date(date).toLocaleDateString()}</time>
      </p>
    </div>
    <section dangerouslySetInnerHTML={{ __html: description }} />
  </article>
);

export default BlogPosts;

function validateFrontmatter(
  input: unknown,
  path: string,
): asserts input is Pick<Post, 'title' | 'date' | 'description'> {
  if (typeof input !== `object` || input === null) {
    throw new Error(`frontmatter from ${path} not an object`);
  }
  const frontmatter = input as Record<string, unknown>;
  if (typeof frontmatter.title !== `string`) {
    throw new Error(`frontmatter.title from ${path} is not a string`);
  }
  if (typeof frontmatter.date !== `string`) {
    throw new Error(`frontmatter.date from ${path} is not a string`);
  }
  if (typeof frontmatter.description !== `string`) {
    throw new Error(`frontmatter.description from ${path} is not a string`);
  }
  if (frontmatter.draft !== undefined && typeof frontmatter.draft !== `boolean`) {
    throw new Error(`frontmatter.draft from ${path} is not a boolean`);
  }
}
