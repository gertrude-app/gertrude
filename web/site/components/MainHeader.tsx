import { Logo } from '@shared/components';
import cx from 'classnames';
import React from 'react';
import FancyLink from './FancyLink';
import MobileLoginDropdown from './MobileLoginDropdown';

const MainHeader: React.FC<{
  theme: `violet` | `white`;
  showAuthButtons?: boolean;
  overlay?: boolean;
  badge?: string;
  linkVariant?: `default` | `flat`;
}> = ({
  theme,
  showAuthButtons = true,
  overlay = false,
  badge,
  linkVariant = `default`,
}) => (
  <header
    className={cx(
      `flex justify-between items-center px-6 xs:px-8 top-0 left-0 right-0 z-50 py-6`,
      overlay ? `absolute` : `relative`,
    )}
  >
    <a href="/" className="flex items-center gap-3">
      <Logo
        className={cx(`transition-opacity duration-500`)}
        type={theme === `violet` ? `inverted` : `default`}
      />
      {badge && (
        <span
          className={cx(
            `text-xs font-bold px-2 py-1 rounded`,
            theme === `violet`
              ? `bg-white/15 text-white border border-white/40 backdrop-blur-sm`
              : `bg-gradient-to-r from-violet-500 to-fuchsia-500 text-white`,
          )}
        >
          {badge}
        </span>
      )}
    </a>
    {showAuthButtons && <MobileLoginDropdown theme={theme} />}
    {showAuthButtons && (
      <div className={cx(`gap-4 transition-opacity duration-500 hidden sm:flex`)}>
        <FancyLink
          type="link"
          href="https://parents.gertrude.app"
          size="sm"
          color="secondary"
          inverted={theme === `violet`}
          variant={linkVariant}
        >
          Log in
        </FancyLink>
        <FancyLink
          type="link"
          href="https://parents.gertrude.app/signup?v=new_site"
          size="sm"
          color="primary"
          inverted={theme === `violet`}
        >
          Sign up
        </FancyLink>
      </div>
    )}
  </header>
);

export default MainHeader;
