import React, { useEffect, useState } from 'react';
import { CheckIcon, ClipboardIcon } from 'lucide-react';
import { createHighlighterCore } from 'shiki/core';
import { createJavaScriptRegexEngine } from 'shiki/engine/javascript';
import tsx from 'shiki/langs/tsx.mjs';
import githubDarkDefault from 'shiki/themes/github-dark-default.mjs';
import { useDemoPageContext } from './DemoPageContext';

const sourceByPath = import.meta.glob<string>('/src/routes/**/examples/*.tsx', {
  query: '?raw',
  import: 'default',
  eager: true,
}) as Record<string, string | undefined>;

const highlighterPromise = createHighlighterCore({
  themes: [githubDarkDefault],
  langs: [tsx],
  engine: createJavaScriptRegexEngine(),
});

interface Props {
  component: React.ReactNode;
  path: string;
  description: string;
}

const normalizeSourcePath = (path: string): string => {
  const parts: string[] = [];

  for (const part of path.split('/')) {
    if (part === '' || part === '.') {
      continue;
    }

    if (part === '..') {
      parts.pop();
      continue;
    }

    parts.push(part);
  }

  return `/${parts.join('/')}`;
};

const resolveSourcePath = (sourceBasePath: string, path: string): string => {
  if (path.startsWith('/src/')) {
    return normalizeSourcePath(path);
  }

  if (path.startsWith('/')) {
    return normalizeSourcePath(`/src/routes${path}`);
  }

  return normalizeSourcePath(`${sourceBasePath}/${path}`);
};

const DemoExample: React.FC<Props> = ({ component, path, description }) => {
  const { sourceBasePath } = useDemoPageContext();
  const sourcePath = resolveSourcePath(sourceBasePath, path);
  const source = sourceByPath[sourcePath];
  const [copied, setCopied] = useState(false);
  const [highlightedSource, setHighlightedSource] = useState<string | null>(null);
  const fileName = sourcePath.split('/').slice(-2).join('/');
  const sourceFileName = sourcePath.split('/').pop() ?? path;
  const exampleTitle = sourceFileName.replace(/\.tsx$/, '').replace(/([a-z0-9])([A-Z])/g, '$1 $2');

  useEffect(() => {
    let isCurrent = true;

    setHighlightedSource(null);

    if (!source) {
      return;
    }

    void highlighterPromise
      .then((highlighter) =>
        highlighter.codeToHtml(source, {
          lang: 'tsx',
          theme: 'github-dark-default',
        }),
      )
      .then((html) => {
        if (isCurrent) {
          setHighlightedSource(html);
        }
      })
      .catch(() => {
        if (isCurrent) {
          setHighlightedSource(null);
        }
      });

    return () => {
      isCurrent = false;
    };
  }, [source]);

  const copyCode = async (): Promise<void> => {
    if (!source) {
      return;
    }

    try {
      await navigator.clipboard.writeText(source);
      setCopied(true);
      window.setTimeout(() => setCopied(false), 1400);
    } catch {
      setCopied(false);
    }
  };

  return (
    <section className="flex flex-col gap-4">
      <div className="max-w-2xl">
        <h2 className="text-xl font-semibold tracking-tight text-stone-950">{exampleTitle}</h2>
        <p className="mt-1.5 leading-7 text-stone-600">{description}</p>
      </div>

      <div className="overflow-hidden rounded-xl border border-stone-200 bg-white shadow-sm">
        <div className="h-[32rem] overflow-auto bg-stone-50">{component}</div>

        <div className="border-t border-stone-800 bg-stone-950 text-stone-100">
          <div className="flex flex-col gap-3 border-b border-stone-800 px-5 py-3 sm:flex-row sm:items-center sm:justify-between">
            <span className="font-mono text-xs text-stone-400">{fileName}</span>
            <button
              type="button"
              onClick={() => void copyCode()}
              disabled={!source}
              className="inline-flex items-center gap-2 self-start rounded-full border border-stone-700 bg-stone-900 px-3 py-1.5 text-xs font-medium text-stone-200 transition hover:bg-stone-800 active:scale-98 disabled:cursor-not-allowed disabled:opacity-50 sm:self-auto"
            >
              {copied ? <CheckIcon className="h-3.5 w-3.5" /> : <ClipboardIcon className="h-3.5 w-3.5" />}
              {copied ? 'Copied' : 'Copy code'}
            </button>
          </div>
          {highlightedSource ? (
            <div
              className="[&>pre]:max-h-[34rem] [&>pre]:overflow-auto [&>pre]:!bg-stone-950 [&>pre]:p-5 [&>pre]:text-sm [&>pre]:leading-6 [&>pre]:outline-none"
              dangerouslySetInnerHTML={{ __html: highlightedSource }}
            />
          ) : (
            <pre className="max-h-[34rem] overflow-auto p-5 text-sm leading-6 text-stone-100">
              <code>{source ?? `Unable to find source for ${sourcePath}`}</code>
            </pre>
          )}
        </div>
      </div>
    </section>
  );
};

export default DemoExample;
