import { ProgressIndicator } from '@shared/components';
import React from 'react';
import FrameBackground from './FrameBackground';

interface Props {
  step: number;
  totalSteps: number;
  title: string;
  subtitle?: string;
  children: React.ReactNode;
  imageSrc?: string;
  imageAlt?: string;
  imagePlaceholder?: string;
  footer: React.ReactNode;
}

const InstructionLayout: React.FC<Props> = ({
  step,
  totalSteps,
  title,
  subtitle,
  children,
  imageSrc,
  imageAlt,
  imagePlaceholder,
  footer,
}) => (
  <FrameBackground>
    <div className="absolute top-0 left-0 w-full p-5 flex justify-center">
      <ProgressIndicator step={step} totalSteps={totalSteps} />
    </div>
    <div className="w-full h-full flex flex-col px-16 pt-16 pb-16">
      <div className="flex-1 flex flex-col justify-center">
        <div className="mb-10">
          <h1 className="text-3xl font-bold text-slate-800 mb-1">{title}</h1>
          {subtitle && <p className="text-slate-500">{subtitle}</p>}
        </div>

        <div className="flex items-start gap-10">
          <div className="flex flex-col flex-1">{children}</div>
          <div className="shrink-0">
            {imageSrc ? (
              <img src={imageSrc} alt={imageAlt} className="w-96 rounded-2xl shadow-lg" />
            ) : (
              <div className="w-96 h-64 bg-slate-200/50 rounded-2xl flex items-center justify-center border-2 border-dashed border-slate-300">
                <p className="text-sm text-slate-400 text-center px-6">
                  {imagePlaceholder}
                </p>
              </div>
            )}
          </div>
        </div>
      </div>

      <div className="flex justify-center pt-4">{footer}</div>
    </div>
  </FrameBackground>
);

export default InstructionLayout;
