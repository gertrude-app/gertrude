import React from 'react';
import WarningBanner from './WarningBanner';

const AccountPastDueBanner: React.FC<{ small?: boolean }> = ({ small }) => (
  <WarningBanner severity="warning">
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
