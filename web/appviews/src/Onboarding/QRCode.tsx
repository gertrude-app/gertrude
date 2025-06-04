import React, { useState } from 'react';
import cx from 'classnames';

interface Props {
  url: string;
}

const QRCode: React.FC<Props> = ({ url }) => {
  const [side, setSide] = useState<`image` | `url`>(`image`);
  const [codeClicked, setCodeClicked] = useState(false);
  const img = `${IMG_ENDPOINT}/${url.replace(/\//g, `__`)}.png`;
  return (
    <div className="flex flex-col justify-center items-center translate-x-4 min-w-[280px]">
      <div
        className={cx(
          `flex flex-col items-center transition-opacity duration-500`,
          codeClicked && `opacity-0`,
        )}
      >
        <span className="text-slate-400 text-sm">Or, click for the URL</span>
        <i className="fa-chevron-down fa-solid text-slate-400 text-sm animate-bounce mt-2 mb-1" />
      </div>
      <div onClick={() => setCodeClicked(true)}>
        <div className="[perspective:400px]">
          <div
            className={cx(
              `h-[200px] relative transition-[transform,box-shadow,width] duration-500 [transform-style:preserve-3d] rounded-3xl shadow-lg shadow-slate-300/30 cursor-pointer hover:shadow-xl hover:shadow-slate-300/60`,
              side === `url` ? `[transform:rotateY(-180deg)] w-[270px]` : `w-[200px]`,
            )}
            onClick={() => setSide(side === `image` ? `url` : `image`)}
          >
            <div className="absolute w-full h-full left-0 top-0 [backface-visibility:hidden] rounded-3xl overflow-hidden">
              <img src={img} className="w-full h-full" alt="QR code" />
            </div>
            <div className="absolute w-full h-full left-0 top-0 [backface-visibility:hidden] rounded-3xl [transform:rotateY(180deg)] bg-white flex flex-col justify-center items-center p-4 space-y-3">
              <span className="text-slate-400 text-sm text-center">
                Enter this URL into your browser:
              </span>
              <span className="select-none break-words font-medium bg-fuchsia-50 text-fuchsia-600 py-2 px-3 rounded-lg">
                https://{url}
              </span>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

export default QRCode;

const IMG_ENDPOINT = `https://gertrude-web-assets.nyc3.cdn.digitaloceanspaces.com/onboarding/qr-codes`;
