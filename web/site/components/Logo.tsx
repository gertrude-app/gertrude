import cx from 'classnames';
import React from 'react';

interface Props {
  size?: number;
  iconOnly?: boolean;
  className?: string;
  type?: `default` | `inverted`;
  withForParents?: boolean | `condensed`;
  badge?: string;
  textSize?: string;
}

const LOGO_ASPECT_RATIO = 668 / 116;

const Logo: React.FC<Props> = ({
  size = 32,
  iconOnly,
  className,
  type = `default`,
  withForParents = false,
  badge,
}) => {
  const src = type === `inverted` ? `/gertrude-logo-white.svg` : `/gertrude-logo.svg`;

  if (iconOnly) {
    return (
      <img
        src="/logo-icon.svg"
        alt="Gertrude"
        className={cx(`block`, className)}
        style={{ width: size, height: size }}
      />
    );
  }

  return (
    <span className={cx(`inline-flex items-center`, className)}>
      <span className="flex flex-col">
        <span className="flex items-center gap-3">
          <img
            src={src}
            alt="Gertrude"
            className="block max-w-none"
            style={{ width: size * LOGO_ASPECT_RATIO, height: size }}
          />
          {badge && (
            <span
              className={cx(
                `whitespace-nowrap rounded px-2 py-1 text-xs font-bold`,
                type === `inverted`
                  ? `border border-white/40 bg-white/15 text-white backdrop-blur-sm`
                  : `bg-gradient-to-r from-violet-500 to-fuchsia-500 text-white`,
              )}
            >
              {badge}
            </span>
          )}
        </span>
        {withForParents && (
          <span
            className={cx(
              type === `inverted`
                ? `from-indigo-400 to-fuchsia-400`
                : `from-indigo-500 to-fuchsia-500`,
              `mt-1 w-fit bg-gradient-to-r bg-clip-text text-sm font-medium uppercase tracking-wider text-transparent [-webkit-background-clip:text]`,
              withForParents === `condensed` && `-mt-0.5 border border-slate-900`,
            )}
          >
            For parents
          </span>
        )}
      </span>
    </span>
  );
};

export default Logo;
