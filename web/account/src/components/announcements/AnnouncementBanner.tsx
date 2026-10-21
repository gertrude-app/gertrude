import { Banner, Button } from '@gertrude/ui';
import DOMPurify from 'dompurify';
import { ArrowUpRightIcon } from 'lucide-react';
import React, { useLayoutEffect, useMemo, useRef, useState } from 'react';
import type { Announcement } from '#/components/types';

interface Props {
  announcement: Announcement;
  onDismiss: () => void;
  dismissing?: boolean;
  error?: string;
}

function announcementHref(url: string): string | undefined {
  try {
    const parsed = new URL(url);
    return parsed.protocol === `https:` || parsed.protocol === `http:`
      ? parsed.href
      : undefined;
  } catch {
    return undefined;
  }
}

function announcementHtml(html: string): string {
  const fragment = DOMPurify.sanitize(html, {
    ALLOWED_TAGS: [`b`, `strong`, `em`, `i`, `p`, `br`, `a`, `ul`, `ol`, `li`],
    ALLOWED_ATTR: [`href`, `title`],
    ALLOW_DATA_ATTR: false,
    ALLOW_ARIA_ATTR: false,
    RETURN_DOM_FRAGMENT: true,
  });
  for (const link of fragment.querySelectorAll(`a`)) {
    const href = announcementHref(link.getAttribute(`href`) ?? ``);
    if (!href) {
      link.removeAttribute(`href`);
    } else {
      link.setAttribute(`href`, href);
      link.setAttribute(`target`, `_blank`);
      link.setAttribute(`rel`, `noreferrer`);
    }
  }
  const container = fragment.ownerDocument.createElement(`div`);
  container.append(fragment);
  return container.innerHTML;
}

const AnnouncementBanner: React.FC<Props> = ({
  announcement,
  onDismiss,
  dismissing,
  error,
}) => {
  const html = useMemo(() => announcementHtml(announcement.html), [announcement.html]);
  const href = announcement.action && announcementHref(announcement.action.url);
  const actionsRef = useRef<HTMLDivElement>(null);
  const [actionsSize, setActionsSize] = useState({ width: 0, height: 0 });

  useLayoutEffect(() => {
    const actions = actionsRef.current;
    if (!actions) return;
    const update = (): void => {
      const { width, height } = actions.getBoundingClientRect();
      setActionsSize({ width, height });
    };
    update();
    if (typeof ResizeObserver === `undefined`) return;
    const observer = new ResizeObserver(update);
    observer.observe(actions);
    return () => observer.disconnect();
  }, []);

  return (
    <section
      aria-label={announcement.kind === `warning` ? `Account warning` : `Announcement`}
      style={
        {
          '--announcement-actions-width': `${actionsSize.width}px`,
          '--announcement-actions-height': `${actionsSize.height}px`,
        } as React.CSSProperties
      }
    >
      <Banner
        variant={announcement.kind === `warning` ? `warning` : `neutral`}
        showIcon={false}
        className="relative p-4 @lg/main:p-5 [&>div]:min-w-0 [&>div]:flex-1"
      >
        <div className="flex min-w-0 flex-col justify-center @3xl/main:min-h-[var(--announcement-actions-height)] @3xl/main:pr-[calc(var(--announcement-actions-width)+1.5rem)]">
          <div
            className="break-words [&_b]:font-semibold [&_p+p]:mt-2 [&_ul]:list-disc [&_ol]:list-decimal [&_ul]:pl-5 [&_ol]:pl-5 [&_a]:underline [&_a]:underline-offset-2"
            dangerouslySetInnerHTML={{ __html: html }}
          />
          {error && (
            <p role="alert" className="mt-2 text-sm font-medium text-red-700">
              {error}
            </p>
          )}
        </div>
        <div
          ref={actionsRef}
          className="mt-4 flex flex-wrap items-center gap-2 @3xl/main:absolute @3xl/main:top-1/2 @3xl/main:right-5 @3xl/main:mt-0 @3xl/main:max-w-[45%] @3xl/main:-translate-y-1/2"
        >
          {href && announcement.action && (
            <Button
              type="link"
              href={href}
              size="small"
              target="_blank"
              rel="noreferrer"
              icon={ArrowUpRightIcon}
              iconPosition="right"
            >
              {announcement.action.label}
            </Button>
          )}
          <Button
            type="button"
            onClick={onDismiss}
            size="small"
            variant="ghost"
            loading={dismissing}
            ariaLabel="Dismiss announcement"
          >
            Dismiss
          </Button>
        </div>
      </Banner>
    </section>
  );
};

export default AnnouncementBanner;
