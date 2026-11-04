import React from 'react';
import type { ShareLinkMethod } from '#/components/devices/InstallIOSAppModal';

type ShareLinkData = { title: string; text: string; url: string };

export function shareLinkMethod(): ShareLinkMethod {
  return `share` in navigator ? `share` : `copy`;
}

export function useShareLink(): {
  method: ShareLinkMethod;
  copied: boolean;
  share: (data: ShareLinkData) => void;
  reset: () => void;
} {
  const [method, setMethod] = React.useState<ShareLinkMethod>(shareLinkMethod);
  const [copied, setCopied] = React.useState(false);

  const copy = (url: string): void => {
    navigator.clipboard.writeText(url).then(
      () => setCopied(true),
      () => setCopied(false),
    );
  };

  return {
    method,
    copied,
    share: (data) => {
      if (method === `copy`) return copy(data.url);
      navigator.share(data).catch((error: unknown) => {
        if (error instanceof DOMException && error.name === `AbortError`) return;
        setMethod(`copy`);
        copy(data.url);
      });
    },
    reset: () => setCopied(false),
  };
}
