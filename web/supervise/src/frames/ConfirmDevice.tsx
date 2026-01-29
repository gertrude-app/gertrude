import { Button } from '@shared/components';
import React from 'react';
import type { ConfirmDeviceProps } from '../types';
import InstructionLayout from '../InstructionLayout';
import connectDeviceImg from '../assets/connect-device.png';

const img: any = connectDeviceImg;
const imgSrc: string = typeof img === `string` ? img : img.src;

const ConfirmDevice: React.FC<ConfirmDeviceProps> = ({
  deviceName,
  iosVersion,
  onConfirm,
  onReject,
}) => (
  <InstructionLayout
    step={3}
    totalSteps={8}
    title="Device Found"
    subtitle="Is this the device you want to supervise?"
    imageSrc={imgSrc}
    imageAlt="Connected device"
    footer={
      <div className="flex gap-4">
        <Button type="button" onClick={onReject} color="secondary" size="large">
          No, that's not it
        </Button>
        <Button type="button" onClick={onConfirm} color="gradient" size="large">
          Yes, continue &rarr;
        </Button>
      </div>
    }
  >
    <div className="bg-white rounded-2xl border border-slate-200 p-6 shadow-sm">
      <div className="space-y-3">
        <div>
          <p className="text-xs text-violet-400 uppercase tracking-wide font-medium">
            Device Name
          </p>
          <p className="text-xl font-semibold text-slate-800">{deviceName}</p>
        </div>
        <div>
          <p className="text-xs text-violet-400 uppercase tracking-wide font-medium">
            iOS Version
          </p>
          <p className="text-lg text-slate-700">{iosVersion}</p>
        </div>
      </div>
    </div>
  </InstructionLayout>
);

export default ConfirmDevice;
