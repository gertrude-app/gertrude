import cx from 'classnames';
import React from 'react';

export type LogoProduct = `macos` | `ios-ipados` | `music`;

interface Props {
  size?: number;
  iconOnly?: boolean;
  className?: string;
  type?: `default` | `inverted`;
  product?: LogoProduct;
  badge?: string;
  textSize?: string;
}

const BASE_LOGO_HEIGHT = 116;
const PRODUCT_LOGOS: Record<
  LogoProduct,
  { src: string; width: number; height: number; alt: string }
> = {
  macos: {
    src: `/gertrude-logo-macos.svg`,
    width: 641,
    height: 194,
    alt: `Gertrude macOS`,
  },
  'ios-ipados': {
    src: `/gertrude-logo-ios-ipados.svg`,
    width: 643,
    height: 194,
    alt: `Gertrude iOS & iPadOS`,
  },
  music: {
    src: `/gertrude-logo-music.svg`,
    width: 640,
    height: 194,
    alt: `Gertrude Music`,
  },
};

const Logo: React.FC<Props> = ({
  size = 32,
  iconOnly,
  className,
  type = `default`,
  product,
  badge,
}) => {
  const productLogo = product ? PRODUCT_LOGOS[product] : undefined;
  const src =
    productLogo?.src ??
    (type === `inverted` ? `/gertrude-logo-white.svg` : `/gertrude-logo.svg`);
  const width = size * ((productLogo?.width ?? 640) / BASE_LOGO_HEIGHT);
  const height = size * ((productLogo?.height ?? BASE_LOGO_HEIGHT) / BASE_LOGO_HEIGHT);

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
            alt={productLogo?.alt ?? `Gertrude`}
            className="block max-w-none"
            style={{ width, height }}
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
      </span>
    </span>
  );
};

export default Logo;
