import { ApiErrorMessage, ClaimScreen, Loading, ScreenShell } from '@dash/components';
import React, { useEffect, useState } from 'react';
import { useNavigate, useParams } from 'react-router-dom';
import type { PodcastsDoneNavState } from './Done';
import type { ChildSelection } from '@dash/components';
import type { T } from '@shared/pairql/dashboard';
import Current from '../../../environment';
import { Key, useQuery } from '../../../hooks';

const ClaimPodcastsDeviceClaim: React.FC = () => {
  const { code = `` } = useParams<{ code: string }>();
  const navigate = useNavigate();
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [error, setError] = useState<string | undefined>();

  const query = useQuery(Key.amClaimData(code), () =>
    Current.api.getAmClaimData({ code: parseInt(code, 10) }),
  );

  useEffect(() => {
    if (!query.isSuccess || !query.data.resumeStep) return;
    const state: PodcastsDoneNavState = {
      subscription: query.data.resumeStep.amSubscription,
      childName: query.data.resumeStep.childName,
      modelName: query.data.modelName,
      iosVersion: query.data.iosVersion,
    };
    navigate(`/claim-podcasts-device/${code}/done`, { replace: true, state });
  }, [
    query.isSuccess,
    query.data?.resumeStep,
    query.data?.modelName,
    query.data?.iosVersion,
    navigate,
    code,
  ]);

  if (query.isPending) {
    return <Loading />;
  }

  if (query.isError) {
    return <ApiErrorMessage error={query.error} />;
  }

  const { children, modelName, deviceType, iosVersion } = query.data;

  const handleSubmit = async (selection: ChildSelection): Promise<void> => {
    setError(undefined);
    setIsSubmitting(true);

    const child: T.ClaimAmDevice.Input[`child`] =
      selection.type === `new`
        ? { case: `newChild`, name: selection.name }
        : { case: `existingChild`, id: selection.id };

    const result = await Current.api.claimAmDevice({ code: parseInt(code, 10), child });

    setIsSubmitting(false);

    if (result.isError) {
      setError(result.error?.userMessage ?? `Something went wrong. Please try again.`);
      return;
    }

    const output = result.valueOrThrow();
    const state: PodcastsDoneNavState = {
      subscription: output.subscription,
      childName: output.childName,
      modelName: output.modelName,
      iosVersion: output.iosVersion,
    };
    navigate(`/claim-podcasts-device/${code}/done`, { state });
  };

  return (
    <ScreenShell title={`Connect ${deviceType}`}>
      <ClaimScreen
        children={children}
        deviceType={deviceType}
        modelName={modelName}
        iosVersion={iosVersion}
        onSubmit={(selection) => void handleSubmit(selection)}
        onCancel={() => navigate(`/`)}
        isSubmitting={isSubmitting}
        error={error}
        app="podcasts"
      />
    </ScreenShell>
  );
};

export default ClaimPodcastsDeviceClaim;
