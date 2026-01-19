import {
  ApiErrorMessage,
  ChildAssignmentPicker,
  DeviceContextBanner,
  Loading,
  PageHeading,
} from '@dash/components';
import React, { useState } from 'react';
import { useNavigate, useParams } from 'react-router-dom';
import type { ChildSelection } from '@dash/components';
import type { T } from '@shared/pairql/dashboard';
import Current from '../../../environment';
import { Key, useQuery } from '../../../hooks';

const SuperviseDeviceClaim: React.FC = () => {
  const { code = `` } = useParams<{ code: string }>();
  const navigate = useNavigate();
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [error, setError] = useState<string | undefined>();

  const query = useQuery(Key.claimDeviceData(code), () =>
    Current.api.getClaimDeviceData({ code: parseInt(code, 10) }),
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

    const childInput: T.ClaimSupervisionCode.Input[`child`] =
      selection.type === `new`
        ? { case: `newChild`, name: selection.name }
        : { case: `existingChild`, id: selection.id };

    const result = await Current.api.claimSupervisionCode({
      code: parseInt(code, 10),
      child: childInput,
    });

    setIsSubmitting(false);

    if (result.isError) {
      setError(result.error?.userMessage ?? `Something went wrong. Please try again.`);
      return;
    }

    navigate(`/supervise-device/${code}/download-helper`);
  };

  const handleCancel = (): void => {
    navigate(`/`);
  };

  return (
    <div className="relative max-w-3xl">
      <PageHeading icon="phone">Connect {deviceType}</PageHeading>
      <div className="mt-8 bg-white rounded-2xl border border-slate-200 p-6">
        <div className="mb-4">
          <DeviceContextBanner
            modelName={modelName}
            iosVersion={iosVersion}
            deviceType={deviceType as `iPhone` | `iPad`}
            label={`Adding ${deviceType}:`}
          />
        </div>
        <div className="mb-6 pb-6 border-b border-slate-100">
          <p className="text-sm text-slate-500 mb-1">Claim code</p>
          <p className="text-2xl font-mono font-semibold text-slate-800 tracking-wider">
            {code}
          </p>
        </div>
        <ChildAssignmentPicker
          children={children}
          onSubmit={(selection) => void handleSubmit(selection)}
          onCancel={handleCancel}
          isSubmitting={isSubmitting}
          error={error}
        />
      </div>
    </div>
  );
};

export default SuperviseDeviceClaim;
