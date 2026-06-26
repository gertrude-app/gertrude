import { ApiErrorMessage, ClaimScreen, Loading, ScreenShell } from '@dash/components';
import React, { useEffect, useState } from 'react';
import { useNavigate, useParams } from 'react-router-dom';
import type { BlockerDoneNavState } from './Done';
import type { ChildSelection } from '@dash/components';
import type { T } from '@shared/pairql/dashboard';
import Current from '../../../environment';
import { Key, useQuery } from '../../../hooks';

const ClaimBlockerDeviceClaim: React.FC = () => {
  const { code = `` } = useParams<{ code: string }>();
  const navigate = useNavigate();
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [error, setError] = useState<string | undefined>();

  const query = useQuery(Key.blockerClaimData(code), () =>
    Current.api.getBlockerClaimData({ code: parseInt(code, 10) }),
  );

  useEffect(() => {
    if (!query.isSuccess || !query.data.resumeStep) return;
    const state: BlockerDoneNavState = {
      childName: query.data.resumeStep.childName,
      childId: query.data.resumeStep.childId,
      deviceId: query.data.resumeStep.deviceId,
      modelName: query.data.modelName,
      iosVersion: query.data.iosVersion,
    };
    navigate(`/claim-blocker-device/${code}/done`, { replace: true, state });
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

    const child: T.ClaimBlockerDevice.Input[`child`] =
      selection.type === `new`
        ? { case: `newChild`, name: selection.name }
        : { case: `existingChild`, id: selection.id };

    const result = await Current.api.claimBlockerDevice({
      code: parseInt(code, 10),
      child,
    });

    setIsSubmitting(false);

    if (result.isError) {
      setError(result.error?.userMessage ?? `Something went wrong. Please try again.`);
      return;
    }

    const output = result.valueOrThrow();
    const state: BlockerDoneNavState = {
      childName: output.childName,
      childId: output.childId,
      deviceId: output.deviceId,
      modelName: output.modelName,
      iosVersion: output.iosVersion,
    };
    navigate(`/claim-blocker-device/${code}/done`, { state });
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
        app="blocker"
      />
    </ScreenShell>
  );
};

export default ClaimBlockerDeviceClaim;
