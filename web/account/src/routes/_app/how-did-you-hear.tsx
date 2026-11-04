import { createFileRoute, useNavigate } from '@tanstack/react-router';
import React from 'react';
import type { SaveAccountReferralSource } from '@shared/pairql/src/account';
import ReferralSourcePage from '#/components/pages/onboarding/ReferralSourcePage';
import { postAuthLocation, validateAuthRedirectSearch } from '#/lib/authRedirect';
import { liveClient } from '#/pairql/client';

const HowDidYouHearRoute: React.FC = () => {
  const { redirect } = Route.useSearch();
  const navigate = useNavigate();
  const [otherText, setOtherText] = React.useState<string | null>(null);

  const next = (): void => {
    void navigate({ ...postAuthLocation(redirect), replace: true });
  };

  const save = (input: SaveAccountReferralSource.Input): void => {
    void liveClient.saveAccountReferralSource(input);
    next();
  };

  return (
    <ReferralSourcePage
      otherText={otherText}
      onOtherTextChange={setOtherText}
      onChoose={(source) => save({ source })}
      onSubmitOther={() => save({ source: `other`, otherText: otherText ?? undefined })}
      onSkip={next}
    />
  );
};

export const Route = createFileRoute(`/_app/how-did-you-hear`)({
  validateSearch: validateAuthRedirectSearch,
  component: HowDidYouHearRoute,
});
