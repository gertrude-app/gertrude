import cx from 'classnames';
import React from 'react';
import { Link } from 'react-router-dom';

type Props = {
  kind?: `warning` | `news`;
  icon: string;
  heading?: string;
  subtext?: string;
  html?: string;
  linkTo?: string;
  linkText?: string;
  learnMoreUrl?: string;
  onDismiss?: () => void;
  className?: string;
};

const AttentionBanner: React.FC<Props> = ({
  kind = `warning`,
  icon,
  heading,
  subtext,
  html,
  linkTo,
  linkText,
  learnMoreUrl,
  onDismiss,
  className,
}) => (
  <div
    className={cx(
      `shadow-md p-4 flex flex-col @xl:flex-row @xl:items-start items-center gap-3 rounded-lg`,
      kind === `warning`
        ? `bg-amber-50 border-2 border-amber-500`
        : `bg-violet-100 border border-violet-400`,
      className,
    )}
  >
    <i
      className={cx(
        `text-3xl mt-1`,
        kind === `warning` ? `text-amber-600` : `text-violet-600`,
        icon,
      )}
    />
    <div
      className={cx(
        `flex-1`,
        html
          ? `flex flex-col @4xl:flex-row @4xl:items-start gap-3 @xl:gap-2 @4xl:gap-6`
          : `flex flex-col @xl:flex-row @xl:items-center @xl:justify-between gap-2 @xl:gap-6`,
      )}
    >
      {html ? (
        <p
          className={cx(
            `text-center @xl:text-left`,
            kind === `warning` ? `text-amber-900` : `text-violet-800`,
          )}
          dangerouslySetInnerHTML={{ __html: html }}
        />
      ) : (
        <div className="text-center @xl:text-left">
          {heading && (
            <p
              className={cx(
                `font-semibold`,
                kind === `warning` ? `text-amber-900` : `text-violet-800`,
              )}
            >
              {heading}
            </p>
          )}
          {subtext && (
            <p
              className={cx(
                `text-sm`,
                kind === `warning` ? `text-amber-700` : `text-violet-600`,
              )}
            >
              {subtext}
            </p>
          )}
        </div>
      )}
      <div className="flex gap-2 justify-center @xl:justify-end whitespace-nowrap">
        {learnMoreUrl && (
          <a
            target="_blank"
            rel="noreferrer"
            href={learnMoreUrl}
            className={cx(
              `px-3 py-1 rounded-md border`,
              kind === `warning`
                ? `text-amber-600 hover:text-amber-800 border-amber-400`
                : `text-violet-500 hover:text-violet-800 border-violet-400`,
            )}
          >
            Learn more
          </a>
        )}
        {linkTo && linkText && (
          <Link
            to={linkTo}
            className={cx(
              `px-3 py-1 rounded-md border`,
              kind === `warning`
                ? `text-amber-600 hover:text-amber-800 border-amber-400`
                : `text-violet-500 hover:text-violet-800 border-violet-400`,
            )}
          >
            {linkText} <i className="fa-solid fa-arrow-right ml-1" />
          </Link>
        )}
        {onDismiss && (
          <button
            onClick={onDismiss}
            className={cx(
              `text-white px-3 py-1 rounded-md border @4xl:mr-1`,
              kind === `warning`
                ? `bg-amber-600 border-amber-600 hover:bg-amber-700`
                : `bg-violet-600 border-violet-600 hover:text-violet-800`,
            )}
          >
            Dismiss
          </button>
        )}
      </div>
    </div>
  </div>
);

export default AttentionBanner;
