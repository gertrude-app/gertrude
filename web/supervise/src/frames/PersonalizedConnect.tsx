import React from 'react';
import type { PersonalizedConnectProps } from '../types';
import FrameBackground from '../FrameBackground';
import connectDeviceImg from '../assets/connect-device.png';

const img: any = connectDeviceImg;
const imgSrc: string = typeof img === `string` ? img : img.src;

const PersonalizedConnect: React.FC<PersonalizedConnectProps> = ({
  childName,
  deviceType,
  modelName,
  iosVersion,
}) => (
  <FrameBackground>
    <div className="w-full h-full flex flex-col px-10 py-10">
      <div className="mb-16">
        <span className="text-sm font-medium uppercase tracking-wider text-violet-500 mb-2 block">
          Step 2 of 3
        </span>
        <h1 className="text-3xl font-bold text-slate-800 mb-1">
          Connect {childName}&rsquo;s {deviceType}
        </h1>
        <p className="text-slate-500">
          {modelName} &middot; iOS {iosVersion}
        </p>
      </div>

      <div className="flex-1 flex items-start gap-10">
        <div className="flex flex-col flex-1">
          <div className="flex flex-col gap-4">
            <div className="flex items-start gap-4">
              <span className="w-8 h-8 rounded-full bg-violet-100 text-violet-600 text-sm font-bold flex items-center justify-center shrink-0 mt-0.5">
                1
              </span>
              <div>
                <span className="text-base font-medium text-slate-700">
                  Plug in the USB cable
                </span>
                <p className="text-sm text-slate-500 mt-0.5">
                  Connect {childName}&rsquo;s {deviceType} to this computer
                </p>
              </div>
            </div>
            <div className="flex items-start gap-4">
              <span className="w-8 h-8 rounded-full bg-violet-100 text-violet-600 text-sm font-bold flex items-center justify-center shrink-0 mt-0.5">
                2
              </span>
              <div>
                <span className="text-base font-medium text-slate-700">
                  Tap &ldquo;Trust&rdquo; on the device
                </span>
                <p className="text-sm text-slate-500 mt-0.5">
                  A prompt will appear on the {deviceType}&rsquo;s screen
                </p>
              </div>
            </div>
          </div>
        </div>

        <div className="shrink-0">
          <img
            src={imgSrc}
            alt="Connect device via USB"
            className="w-96 rounded-2xl shadow-lg"
          />
        </div>
      </div>

      <div className="flex justify-center pt-6">
        <div className="flex items-center gap-3 text-violet-500">
          <svg className="w-5 h-5 animate-spin" fill="none" viewBox="0 0 24 24">
            <circle
              className="opacity-25"
              cx="12"
              cy="12"
              r="10"
              stroke="currentColor"
              strokeWidth="4"
            />
            <path
              className="opacity-75"
              fill="currentColor"
              d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"
            />
          </svg>
          <span className="text-base font-medium">Waiting for connection...</span>
        </div>
      </div>
    </div>
  </FrameBackground>
);

export default PersonalizedConnect;
