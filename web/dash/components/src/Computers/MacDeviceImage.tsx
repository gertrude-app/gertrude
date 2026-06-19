import cx from 'classnames';
import React, { useState } from 'react';

type Props = {
  modelIdentifier: string;
  modelTitle: string;
  className?: string;
};

type FallbackProps = {
  title: string;
  className?: string;
};

const UNKNOWN_MODEL = /\bunknown\b/i;

const MacDeviceImage: React.FC<Props> = ({ modelIdentifier, modelTitle, className }) => {
  const [imageFailed, setImageFailed] = useState(false);

  if (
    !modelIdentifier ||
    imageFailed ||
    UNKNOWN_MODEL.test(modelTitle) ||
    UNKNOWN_MODEL.test(modelIdentifier)
  ) {
    return <MacDeviceFallback title={modelTitle} className={className} />;
  }

  return (
    <img
      alt={modelTitle}
      src={`/macs/${modelIdentifier}.png`}
      className={cx(`max-h-full max-w-full object-contain`, className)}
      onError={() => setImageFailed(true)}
    />
  );
};

const MacDeviceFallback: React.FC<FallbackProps> = ({ title, className }) => (
  <div
    className={cx(
      `@container flex h-full w-full items-center justify-center text-slate-400`,
      className,
    )}
    role="img"
    aria-label={title || `Mac computer`}
  >
    <i className="fa-solid fa-laptop text-[72cqw]" aria-hidden="true" />
  </div>
);

export default MacDeviceImage;
