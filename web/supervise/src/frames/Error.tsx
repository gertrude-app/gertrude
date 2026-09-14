import { Button } from '@shared/components';
import React from 'react';
import type { ErrorProps, ErrorType } from '../types';
import FrameBackground from '../FrameBackground';

function getErrorContent(
  errorType: ErrorType,
  deviceType: string,
  errorMessage?: string,
): {
  title: string;
  message: string;
} {
  switch (errorType) {
    case `findMyEnabled`:
      return {
        title: `Find My ${deviceType} is Enabled`,
        message: `Find My ${deviceType} must be disabled before supervision can complete. Please disable it in Settings → [Your Name] → Find My, then try again.`,
      };
    case `userReportedNo`:
      return {
        title: `Supervision Unsuccessful`,
        message: `The ${deviceType} doesn't appear to be supervised. You can try the process again, or contact support for help.`,
      };
    case `deviceLimitReached`:
      return {
        title: `Device Limit Reached`,
        message:
          errorMessage ??
          `This account has supervised more devices than Gertrude allows. Get in touch and we'll sort it out with you.`,
      };
    case `serverRejected`:
      return {
        title: `Can't Continue`,
        message:
          errorMessage ??
          `Gertrude couldn't start supervising this ${deviceType}. Please try again or contact support.`,
      };
    case `invokeFailed`:
    default:
      return {
        title: `Something Went Wrong`,
        message: errorMessage
          ? `Supervision could not be completed. Error: ${errorMessage}`
          : `Supervision could not be completed. Please try again or contact support.`,
      };
  }
}

const Error: React.FC<ErrorProps> = ({
  deviceType,
  errorType,
  errorMessage,
  onRetry,
  onContactSupport,
}) => {
  const { title, message } = getErrorContent(errorType, deviceType, errorMessage);

  return (
    <FrameBackground>
      <div className="w-full h-full flex flex-col items-center justify-center px-10 py-10">
        <div className="flex flex-col items-center gap-6 max-w-md">
          <div className="w-20 h-20 rounded-full bg-red-100 flex items-center justify-center">
            <svg
              className="w-10 h-10 text-red-600"
              fill="none"
              viewBox="0 0 24 24"
              stroke="currentColor"
            >
              <path
                strokeLinecap="round"
                strokeLinejoin="round"
                strokeWidth={1.5}
                d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z"
              />
            </svg>
          </div>

          <div className="text-center">
            <h1 className="text-3xl font-bold text-slate-800 mb-3">{title}</h1>
            <p className="text-slate-500">{message}</p>
          </div>

          <div className="flex gap-4 mt-4">
            <Button
              type="button"
              onClick={onContactSupport}
              color={errorType === `deviceLimitReached` ? `gradient` : `secondary`}
              size="large"
            >
              Contact Support
            </Button>
            {errorType !== `deviceLimitReached` && (
              <Button type="button" onClick={onRetry} color="gradient" size="large">
                Try Again &rarr;
              </Button>
            )}
          </div>
        </div>
      </div>
    </FrameBackground>
  );
};

export default Error;
