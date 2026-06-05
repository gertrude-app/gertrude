import React from 'react';
import type { ChildSelection } from './ChildAssignmentPicker';
import type { GertrudeIOSApp } from '../gertrudeApps';
import DeviceContextBanner from '../Unauthed/DeviceContextBanner';
import ChildAssignmentPicker from './ChildAssignmentPicker';

const ClaimScreen: React.FC<{
  children: Array<{ id: string; name: string }>;
  deviceType: string;
  modelName: string;
  iosVersion: string;
  onSubmit: (selection: ChildSelection) => void;
  onCancel: () => void;
  isSubmitting: boolean;
  error?: string;
  app?: GertrudeIOSApp;
}> = ({
  children,
  deviceType,
  modelName,
  iosVersion,
  onSubmit,
  onCancel,
  isSubmitting,
  error,
  app = `blocker`,
}) => (
  <>
    <div className="mb-8">
      <DeviceContextBanner
        modelName={modelName}
        iosVersion={iosVersion}
        deviceType={deviceType as `iPhone` | `iPad`}
        label={`Adding ${deviceType}:`}
        app={app}
      />
    </div>
    <ChildAssignmentPicker
      children={children}
      deviceType={deviceType}
      onSubmit={onSubmit}
      onCancel={onCancel}
      isSubmitting={isSubmitting}
      error={error}
    />
  </>
);

export default ClaimScreen;
