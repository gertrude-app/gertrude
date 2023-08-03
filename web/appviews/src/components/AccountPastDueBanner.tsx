import React from 'react';
import WarningBanner from './WarningBanner';

const AccountPastDueBanner: React.FC<{ small?: boolean; withoutBorder?: boolean }> = ({
  small,
  withoutBorder = false,
}) => (
  <WarningBanner severity="warning" withoutBorder={withoutBorder}>
    Your Gertrude account is past due!{` `}
    {!small && (
      <>
        Login to the web admin dashboard before the app
        {` `}
        <b>loses functionality.</b>
      </>
    )}
  </WarningBanner>
);
export default AccountPastDueBanner;
