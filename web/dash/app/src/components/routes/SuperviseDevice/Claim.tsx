import { ApiErrorMessage, Loading } from '@dash/components';
import React, { useState } from 'react';
import { useNavigate, useParams } from 'react-router-dom';
import type { ChildSelection } from '@dash/components';
import type { T } from '@shared/pairql/dashboard';
import Current from '../../../environment';
import { Key, useQuery } from '../../../hooks';
import { ClaimScreen, ScreenShell } from './screens';

const SuperviseDeviceClaim: React.FC = () => {
  const { code = `` } = useParams<{ code: string }>();
  const navigate = useNavigate();
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [error, setError] = useState<string | undefined>();

  const query = useQuery(Key.claimDeviceData(code), () =>
    Current.api.getIOSDeviceClaimData({ code: parseInt(code, 10) }),
  );

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

    const childInput: T.ClaimIOSDevice.Input[`child`] =
      selection.type === `new`
        ? { case: `newChild`, name: selection.name }
        : { case: `existingChild`, id: selection.id };

    const result = await Current.api.claimIOSDevice({
      code: parseInt(code, 10),
      child: childInput,
    });

    setIsSubmitting(false);

    if (result.isError) {
      setError(result.error?.userMessage ?? `Something went wrong. Please try again.`);
      return;
    }

    navigate(`/supervise-device/${code}/payment`);
  };

  const handleCancel = (): void => {
    navigate(`/`);
  };

  return (
    <ScreenShell title={`Connect ${deviceType}`}>
      <ClaimScreen
        children={children}
        deviceType={deviceType}
        modelName={modelName}
        iosVersion={iosVersion}
        onSubmit={(selection) => void handleSubmit(selection)}
        onCancel={handleCancel}
        isSubmitting={isSubmitting}
        error={error}
      />
    </ScreenShell>
  );
};

export default SuperviseDeviceClaim;
