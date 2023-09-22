import React, { useState } from 'react';
import cx from 'classnames';

interface Props {
  img: string;
  url: string;
}

const QRCode: React.FC<Props> = ({ img, url }) => {
  const [side, setSide] = useState<'qr' | 'url'>(`qr`);
  return (
    <div className="[perspective:400px]">
      <div
        className={cx(
          `w-[200px] h-[200px] relative transition-[transform,box-shadow] duration-500 [transform-style:preserve-3d] rounded-3xl shadow-lg shadow-slate-300/30 cursor-pointer hover:shadow-xl hover:shadow-slate-300/60`,
          side === `url` && `[transform:rotateY(-180deg)]`,
        )}
        onClick={() => setSide(side === `qr` ? `url` : `qr`)}
      >
        <div className="absolute w-full h-full left-0 top-0 [backface-visibility:hidden] rounded-3xl overflow-hidden">
          <img src={img} className="w-full h-full" alt="QR code" />
        </div>
        <div className="absolute w-full h-full left-0 top-0 [backface-visibility:hidden] rounded-3xl [transform:rotateY(180deg)] bg-white flex flex-col justify-center items-center p-4 gap-3">
          <span className="text-slate-400 text-sm text-center">
            Enter this url into your browser:
          </span>
          <span className="select-none w-44 break-words font-medium bg-fuchsia-50 text-fuchsia-600 p-2 rounded-lg">
            {url}
          </span>
        </div>
      </div>
    </div>
  );
};

export default QRCode;
