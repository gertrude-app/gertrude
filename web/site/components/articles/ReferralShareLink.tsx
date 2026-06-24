'use client';

import { CheckIcon, CopyIcon } from 'lucide-react';
import React, { useEffect, useState } from 'react';
import { copyToClipboard, friendShareUrl } from './referralLink';
import Button from '@/components/Button';

const ReferralShareLink: React.FC = () => {
  const [shareUrl, setShareUrl] = useState<string | undefined>(undefined);
  const [status, setStatus] = useState<`idle` | `copied` | `failed`>(`idle`);

  useEffect(() => {
    const code = new URL(window.location.href).searchParams.get(`code`);
    setShareUrl(friendShareUrl(code));
  }, []);

  useEffect(() => {
    if (status !== `copied`) {
      return;
    }
    const timeout = setTimeout(() => setStatus(`idle`), 2500);
    return () => clearTimeout(timeout);
  }, [status]);

  if (!shareUrl) {
    return null;
  }

  async function onCopy(): Promise<void> {
    const copied = await copyToClipboard(shareUrl ?? ``);
    setStatus(copied ? `copied` : `failed`);
  }

  return (
    <>
      <h2>Your share link</h2>
      <p>
        Here&rsquo;s your personal referral link&mdash;copy it and send it to a friend you
        think would love Gertrude, or post it in a forum or social media channel where it
        would be valuable to other parents.
      </p>
      <div className="not-prose my-8 rounded-3xl border border-slate-200 bg-slate-50 p-6 xs:p-8">
        <div className="flex flex-col gap-3 sm:flex-row sm:items-center">
          <code className="flex-auto select-all break-all rounded-2xl border border-slate-200 bg-white px-4 py-3 font-mono text-sm text-slate-700 sm:text-base">
            {shareUrl}
          </code>
          <Button
            type="button"
            onClick={onCopy}
            color={status === `copied` ? `success` : `primary`}
            size="sm"
            Icon={status === `copied` ? CheckIcon : CopyIcon}
            className="flex-none"
          >
            {status === `copied` ? `Copied` : `Copy link`}
          </Button>
        </div>
        {status === `failed` && (
          <p className="mt-3 text-sm text-slate-500">
            We couldn&rsquo;t copy automatically &mdash; select the link above and copy it
            manually.
          </p>
        )}
      </div>
    </>
  );
};

export default ReferralShareLink;
