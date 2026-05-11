import React, { useEffect, useState } from 'react';
import { CheckIcon, ClipboardIcon } from 'lucide-react';
import { createHighlighterCore } from 'shiki/core';
import { createJavaScriptRegexEngine } from 'shiki/engine/javascript';
import tsx from 'shiki/langs/tsx.mjs';
import githubLightDefault from 'shiki/themes/github-light-default.mjs';
import { useDemoPageContext } from './DemoPageContext';

const sourceByPath = import.meta.glob<string>('/src/routes/**/examples/*.tsx', {
  query: '?raw',
  import: 'default',
  eager: true,
}) as Record<string, string | undefined>;

const highlighterPromise = createHighlighterCore({
  themes: [githubLightDefault],
  langs: [tsx],
  engine: createJavaScriptRegexEngine(),
});

interface Props {
  component: React.ReactNode;
  path: string;
  description: string;
  demoHeight?: React.CSSProperties['height'];
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

const DemoExample: React.FC<Props> = ({ component, path, description, demoHeight = '32rem' }) => {
  const { sourceBasePath } = useDemoPageContext();
  const sourcePath = resolveSourcePath(sourceBasePath, path);
  const source = sourceByPath[sourcePath];
  const [copied, setCopied] = useState(false);
  const [isCodeVisible, setIsCodeVisible] = useState(false);
  const [highlightedSource, setHighlightedSource] = useState<string | null>(null);
  const fileName = sourcePath.split('/').slice(-2).join('/');
  const sourceFileName = sourcePath.split('/').pop() ?? path;
  const exampleTitle = sourceFileName.replace(/\.tsx$/, '').replace(/([a-z0-9])([A-Z])/g, '$1 $2');

  useEffect(() => {
    let isCurrent = true;

    setHighlightedSource(null);

    if (!source || !isCodeVisible) {
      return;
    }

    void highlighterPromise
      .then((highlighter) =>
        highlighter.codeToHtml(source, {
          lang: 'tsx',
          theme: 'github-light-default',
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
  }, [isCodeVisible, source]);

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
        <div className="overflow-auto bg-stone-50" style={{ height: demoHeight }}>
          {component}
        </div>

        <div className="border-t border-stone-200 bg-white text-stone-950">
          <div className="flex flex-col gap-3 px-5 py-3 sm:flex-row sm:items-center sm:justify-between">
            <span className="font-mono text-xs text-stone-500">{fileName}</span>
            <div className="flex gap-2">
              {isCodeVisible ? (
                <button
                  type="button"
                  onClick={() => void copyCode()}
                  disabled={!source}
                  className="inline-flex items-center gap-2 rounded-full border border-stone-200 bg-white px-3 py-1.5 text-xs font-medium text-stone-700 transition hover:bg-stone-50 active:scale-98 disabled:cursor-not-allowed disabled:opacity-50"
                >
                  {copied ? <CheckIcon className="h-3.5 w-3.5" /> : <ClipboardIcon className="h-3.5 w-3.5" />}
                  {copied ? 'Copied' : 'Copy code'}
                </button>
              ) : null}
              <button
                type="button"
                onClick={() => setIsCodeVisible((visible) => !visible)}
                className="inline-flex rounded-full border border-stone-200 bg-stone-100 px-3 py-1.5 text-xs font-medium text-stone-800 transition hover:bg-stone-200 active:scale-98"
              >
                {isCodeVisible ? 'Hide code' : 'Show code'}
              </button>
            </div>
          </div>
          {isCodeVisible ? (
            <div className="border-t border-stone-200">
              {highlightedSource ? (
                <div
                  className="[&>pre]:max-h-[34rem] [&>pre]:overflow-auto [&>pre]:!bg-white [&>pre]:p-5 [&>pre]:text-sm [&>pre]:leading-6 [&>pre]:outline-none"
                  dangerouslySetInnerHTML={{ __html: highlightedSource }}
                />
              ) : (
                <pre className="max-h-[34rem] overflow-auto bg-white p-5 text-sm leading-6 text-stone-800">
                  <code>{source ?? `Unable to find source for ${sourcePath}`}</code>
                </pre>
              )}
            </div>
          ) : null}
        </div>
      </div>
    </section>
  );
};

export default DemoExample;
