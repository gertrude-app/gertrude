import React from 'react';
import WarningBanner from './WarningBanner';

const AccountPastDueBanner: React.FC<{
  small?: boolean;
  withoutBorder?: boolean;
  className?: string;
}> = ({ small, withoutBorder = false, className }) => (
  <WarningBanner
    severity="warning"
    withoutBorder={withoutBorder}
    className={className ?? ``}
  >
    Gertrude account is past due!{` `}
    {!small && (
      <>
        Login to the Gertrude parent site before the app
        {` `}
        <b>loses functionality.</b>
      </>
    )}
  </WarningBanner>
);
export default AccountPastDueBanner;
