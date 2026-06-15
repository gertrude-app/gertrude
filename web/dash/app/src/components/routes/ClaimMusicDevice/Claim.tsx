import { ApiErrorMessage, ClaimScreen, Loading, ScreenShell } from '@dash/components';
import React, { useEffect, useState } from 'react';
import { useNavigate, useParams } from 'react-router-dom';
import type { MusicDoneNavState } from './Done';
import type { ChildSelection } from '@dash/components';
import type { T } from '@shared/pairql/dashboard';
import Current from '../../../environment';
import { Key, useQuery } from '../../../hooks';

const ClaimMusicDeviceClaim: React.FC = () => {
  const { code = `` } = useParams<{ code: string }>();
  const navigate = useNavigate();
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [error, setError] = useState<string | undefined>();

  const query = useQuery(Key.musicClaimData(code), () =>
    Current.api.getMusicClaimData({ code: parseInt(code, 10) }),
  );

  useEffect(() => {
    if (!query.isSuccess || !query.data.resumeStep) return;
    const state: MusicDoneNavState = {
      childName: query.data.resumeStep.childName,
      modelName: query.data.modelName,
      iosVersion: query.data.iosVersion,
    };
    navigate(`/claim-music-device/${code}/done`, { replace: true, state });
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

    const child: T.ClaimMusicDevice.Input[`child`] =
      selection.type === `new`
        ? { case: `newChild`, name: selection.name }
        : { case: `existingChild`, id: selection.id };

    const result = await Current.api.claimMusicDevice({
      code: parseInt(code, 10),
      child,
    });

    setIsSubmitting(false);

    if (result.isError) {
      setError(result.error?.userMessage ?? `Something went wrong. Please try again.`);
      return;
    }

    const output = result.valueOrThrow();
    const state: MusicDoneNavState = {
      childName: output.childName,
      modelName: output.modelName,
      iosVersion: output.iosVersion,
    };
    navigate(`/claim-music-device/${code}/done`, { state });
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
        app="music"
      />
    </ScreenShell>
  );
};

export default ClaimMusicDeviceClaim;
