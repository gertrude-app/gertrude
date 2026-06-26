import cx from 'classnames';
import React from 'react';

interface Props {
  size?: number;
  iconOnly?: boolean;
  className?: string;
  type?: `default` | `inverted`;
  withForParents?: boolean | `condensed`;
}

const LOGO_WIDTH = 640;
const LOGO_HEIGHT = 194;
const Logo: React.FC<Props> = ({ size = 53, iconOnly, className, type = `default` }) => {
  if (iconOnly) {
    return (
      <img
        src={type === `inverted` ? `/logo-icon-light.svg` : `/logo-icon.svg`}
        alt="Gertrude for Parents"
        className={cx(`block`, className)}
        style={{ width: size, height: size }}
      />
    );
  }

  return (
    <img
      src="/gertrude-for-parents-logo.svg"
      alt="Gertrude for Parents"
      className={cx(`block max-w-none`, className)}
      style={{ width: (size * LOGO_WIDTH) / LOGO_HEIGHT, height: size }}
    />
  );
};

export default Logo;
