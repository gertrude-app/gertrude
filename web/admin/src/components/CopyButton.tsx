import React, { useState } from 'react';
import { CheckIcon, CopyIcon, LinkIcon } from './Icons';

interface CopyButtonProps {
  text: string;
}

export const CopyButton: React.FC<CopyButtonProps> = ({ text }) => {
  const [copied, setCopied] = useState(false);

  const handleCopy = async (): Promise<void> => {
    await navigator.clipboard.writeText(text);
    setCopied(true);
    setTimeout(() => setCopied(false), 1500);
  };

  return (
    <button
      onClick={handleCopy}
      className="p-1 rounded hover:bg-slate-100 text-slate-400 hover:text-slate-600 transition-colors"
      title="Copy to clipboard"
    >
      {copied ? (
        <CheckIcon className="w-4 h-4 text-emerald-500" />
      ) : (
        <CopyIcon className="w-4 h-4" />
      )}
    </button>
  );
};

interface CopyLinkButtonProps {
  childId: string;
}

export const CopyLinkButton: React.FC<CopyLinkButtonProps> = ({ childId }) => {
  const [copied, setCopied] = useState(false);

  const handleCopy = async (): Promise<void> => {
    const url = `https://parents.gertrude.app/children/${childId.toLowerCase()}`;
    await navigator.clipboard.writeText(url);
    setCopied(true);
    setTimeout(() => setCopied(false), 2000);
  };

  return (
    <button
      onClick={handleCopy}
      className="inline-flex items-center gap-1.5 px-2 py-1 rounded-lg text-slate-400 hover:text-slate-600 hover:bg-slate-100 transition-colors text-xs"
      title="Copy child settings link"
    >
      {copied ? (
        <>
          <CheckIcon className="w-3.5 h-3.5 text-emerald-500" />
          <span className="text-emerald-600 font-medium">Child settings link copied</span>
        </>
      ) : (
        <LinkIcon className="w-3.5 h-3.5" />
      )}
    </button>
  );
};
