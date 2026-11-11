import cx from 'clsx';
import React from 'react';
import { encode } from 'uqr';

interface Props {
  value: string;
  label: string;
  center?: React.ReactNode;
  className?: string;
}

const QrCode: React.FC<Props> = ({ value, label, center, className }) => {
  const hasCenter = center !== undefined;
  const { size, path } = React.useMemo(() => {
    const qr = encode(value, { ecc: hasCenter ? `H` : `M`, border: 0 });
    return {
      size: qr.size,
      path: qr.data
        .flatMap((row, y) => row.map((dark, x) => (dark ? `M${x} ${y}h1v1h-1z` : ``)))
        .join(``),
    };
  }, [value, hasCenter]);

  return (
    <div className={cx(`relative`, className)}>
      <svg
        role="img"
        aria-label={label}
        viewBox={`0 0 ${size} ${size}`}
        shapeRendering="crispEdges"
        className="block size-full text-stone-950"
      >
        <path d={path} fill="currentColor" />
      </svg>
      {hasCenter && (
        <span className="absolute inset-0 flex items-center justify-center">
          <span className="flex rounded-2xl bg-white p-1">{center}</span>
        </span>
      )}
    </div>
  );
};

export default QrCode;
