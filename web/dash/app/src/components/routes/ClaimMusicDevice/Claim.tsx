import { ApiErrorMessage, ClaimScreen, Loading, ScreenShell } from '@dash/components';
import { Result } from '@shared/pairql';
import React, { useEffect, useState } from 'react';
import { useNavigate, useParams, useSearchParams } from 'react-router-dom';
import type { MusicDoneNavState } from './Done';
import type { ChildSelection } from '@dash/components';
import type { T } from '@shared/pairql/dashboard';
import Current from '../../../environment';
import { Key, useFireAndForget, useQuery } from '../../../hooks';

const ClaimMusicDeviceClaim: React.FC = () => {
  const { code = `` } = useParams<{ code: string }>();
  const navigate = useNavigate();
  const [searchParams] = useSearchParams();
  const sessionId = searchParams.get(`session_id`);
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [error, setError] = useState<string | undefined>();

  const checkoutSuccess = useFireAndForget(
    () => {
      if (!sessionId) return Result.resolveUnexpected(`df13e60f`);
      return Current.api.handleCheckoutSuccess({ stripeCheckoutSessionId: sessionId });
    },
    { when: !!sessionId },
  );

  const query = useQuery(
    Key.musicClaimData(code),
    () => Current.api.getMusicClaimData({ code: parseInt(code, 10) }),
    { enabled: !sessionId || checkoutSuccess.isSuccess },
  );

  useEffect(() => {
    if (checkoutSuccess.isSuccess) {
      navigate(`/claim-music-device/${code}/claim`, { replace: true });
    }
  }, [checkoutSuccess.isSuccess, navigate, code]);

  useEffect(() => {
    if (!query.isSuccess) return;

    if (query.data.paymentAction) {
      navigate(`/claim-music-device/${code}/payment`, { replace: true });
      return;
    }

    if (query.data.resumeStep) {
      const state: MusicDoneNavState = {
        childName: query.data.resumeStep.childName,
        modelName: query.data.modelName,
        iosVersion: query.data.iosVersion,
      };
      navigate(`/claim-music-device/${code}/done`, { replace: true, state });
    }
  }, [
    query.isSuccess,
    query.data?.paymentAction,
    query.data?.resumeStep,
    query.data?.modelName,
    query.data?.iosVersion,
    navigate,
    code,
  ]);

  if (sessionId && checkoutSuccess.isPending) {
    return <Loading />;
  }

  if (checkoutSuccess.isError) {
    return <ApiErrorMessage error={checkoutSuccess.error} />;
  }

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
