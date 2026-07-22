import cx from 'classnames';
import { ImageIcon } from 'lucide-react';
import React from 'react';

export const MUSIC_APP_STORE_URL = `https://apps.apple.com/us/app/gertrude-music/id6782194077`;

export const AppStoreLink: React.FC<{ className?: string }> = ({ className }) => (
  <a
    href={MUSIC_APP_STORE_URL}
    target="_blank"
    rel="noopener noreferrer"
    className={cx(
      `inline-flex rounded-xl transition-transform duration-200 hover:-translate-y-0.5 focus:outline-none focus-visible:ring-2 focus-visible:ring-fuchsia-300 focus-visible:ring-offset-2`,
      className,
    )}
  >
    <img
      src="/download-on-app-store.svg"
      alt="Download Gertrude Music on the App Store"
      width={180}
      height={60}
      className="h-[3.75rem] w-auto"
    />
  </a>
);

export const MediaPlaceholder: React.FC<{
  title: string;
  detail: string;
  dark?: boolean;
  className?: string;
}> = ({ title, detail, dark = false, className }) => (
  <div
    className={cx(
      `flex w-full min-w-0 items-center justify-center overflow-hidden rounded-[2rem] border p-8 text-center sm:rounded-[2.5rem] sm:p-12`,
      dark
        ? `border-white/10 bg-white/[0.06] text-white`
        : `border-violet-200 bg-gradient-to-br from-white via-violet-50 to-fuchsia-100 text-slate-900`,
      className,
    )}
  >
    <div className="max-w-sm">
      <span
        className={cx(
          `mx-auto flex size-12 items-center justify-center rounded-2xl`,
          dark ? `bg-white/10 text-fuchsia-300` : `bg-white text-violet-600 shadow-sm`,
        )}
      >
        <ImageIcon className="size-5" />
      </span>
      <p className="mt-5 text-base font-semibold sm:text-lg">{title}</p>
      <p
        className={cx(
          `mt-2 text-sm leading-relaxed`,
          dark ? `text-white/50` : `text-slate-500`,
        )}
      >
        {detail}
      </p>
    </div>
  </div>
);
