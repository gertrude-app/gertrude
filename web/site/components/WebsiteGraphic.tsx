import cx from 'classnames';
import { BanIcon, CheckIcon } from 'lucide-react';
import React from 'react';

interface Props {
  variant: 1 | 2 | 3;
  initiallyAllowed: boolean;
  bottom: number;
  className?: string;
  intersected?: boolean;
}

const WebsiteGraphic: React.FC<Props> = ({
  variant,
  initiallyAllowed,
  bottom,
  className,
  intersected,
}) => {
  const [allowed, setAllowed] = React.useState(initiallyAllowed);
  let graphic: React.ReactNode = <svg />;
  const raised = allowed && intersected;
  switch (variant) {
    case 1:
      graphic = (
        <svg
          width="150"
          height="150"
          viewBox="0 0 150 150"
          fill="none"
          xmlns="http://www.w3.org/2000/svg"
        >
          <g clipPath="url(#clip0_1_4)">
            <rect width="150" height="150" rx="12" fill="white" />
            <rect x="-1" y="-1" width="151" height="24" fill="#E2E8F0" />
            <rect x="62" y="6" width="80" height="12" rx="6" fill="#CBD5E1" />
            <rect x="8" y="6" width="12" height="12" rx="4" fill="#8B5CF6" />
            <rect x="22" y="8" width="22" height="3" rx="1.5" fill="#94A3B8" />
            <rect x="22" y="13" width="14" height="3" rx="1.5" fill="#94A3B8" />
            <rect x="88" y="53" width="54" height="3" rx="1.5" fill="#CBD5E1" />
            <rect x="88" y="59" width="54" height="3" rx="1.5" fill="#CBD5E1" />
            <rect x="88" y="65" width="54" height="3" rx="1.5" fill="#CBD5E1" />
            <rect x="88" y="71" width="54" height="3" rx="1.5" fill="#CBD5E1" />
            <rect x="88" y="77" width="54" height="3" rx="1.5" fill="#CBD5E1" />
            <rect x="88" y="83" width="45" height="3" rx="1.5" fill="#CBD5E1" />
            <rect x="8" y="32" width="72" height="54" rx="4" fill="#EDE9FE" />
            <rect x="88" y="32" width="54" height="16" rx="4" fill="#A78BFA" />
            <rect x="8" y="94" width="134" height="24" rx="4" fill="#E2E8F0" />
            <rect x="12" y="98" width="16" height="16" rx="4" fill="#94A3B8" />
            <rect x="32" y="98" width="62" height="16" rx="4" fill="#F1F5F9" />
            <rect x="98" y="98" width="40" height="16" rx="4" fill="#CBD5E1" />
            <rect x="8" y="126" width="134" height="27" rx="4" fill="#F1F5F9" />
            <rect x="12" y="130" width="57" height="24" rx="4" fill="#A78BFA" />
            <rect x="73" y="130" width="65" height="24" rx="4" fill="#E2E8F0" />
          </g>
          <defs>
            <clipPath id="clip0_1_4">
              <rect width="150" height="150" rx="12" fill="white" />
            </clipPath>
          </defs>
        </svg>
      );
      break;
    case 2:
      graphic = (
        <svg
          width="150"
          height="150"
          viewBox="0 0 150 150"
          fill="none"
          xmlns="http://www.w3.org/2000/svg"
        >
          <g clipPath="url(#clip0_3_270)">
            <rect width="150" height="150" rx="12" fill="white" />
            <rect x="34" y="37" width="30" height="6" rx="2" fill="#94A3B8" />
            <rect x="68" y="37" width="47" height="6" rx="2" fill="#94A3B8" />
            <rect x="28" y="47" width="64" height="6" rx="2" fill="#C4B5FD" />
            <rect x="96" y="47" width="25" height="6" rx="2" fill="#94A3B8" />
            <rect x="112" y="6" width="25" height="4" rx="2" fill="#CBD5E1" />
            <rect x="92" y="6" width="16" height="4" rx="2" fill="#CBD5E1" />
            <rect x="66" y="6" width="22" height="4" rx="2" fill="#CBD5E1" />
            <rect x="37" y="65" width="32" height="10" rx="4" fill="#E2E8F0" />
            <rect x="73" y="65" width="39" height="10" rx="4" fill="#A78BFA" />
            <rect y="108" width="150" height="42" fill="#A78BFA" />
            <rect x="12" y="4" width="8" height="8" rx="4" fill="#A78BFA" />
            <rect x="8" y="116" width="50" height="39" rx="4" fill="#DDD6FE" />
            <rect x="66" y="116" width="76" height="39" rx="4" fill="#C4B5FD" />
          </g>
          <defs>
            <clipPath id="clip0_3_270">
              <rect width="150" height="150" rx="12" fill="white" />
            </clipPath>
          </defs>
        </svg>
      );
      break;
    case 3:
      graphic = (
        <svg
          width="150"
          height="150"
          viewBox="0 0 150 150"
          fill="none"
          xmlns="http://www.w3.org/2000/svg"
        >
          <g clipPath="url(#clip0_4_306)">
            <rect width="150" height="150" rx="12" fill="white" />
            <rect width="151" height="18" fill="#E2E8F0" />
            <rect x="47" y="6" width="48" height="6" rx="3" fill="#A78BFA" />
            <rect x="97" y="6" width="6" height="6" rx="3" fill="#A78BFA" />
            <rect y="18" width="36" height="132" fill="#F1F5F9" />
            <rect x="3" y="22" width="30" height="6" rx="3" fill="white" />
            <rect x="28" y="23" width="4" height="4" rx="2" fill="#C4B5FD" />
            <rect x="3" y="33" width="30" height="8" rx="2" fill="#E2E8F0" />
            <rect x="3" y="44" width="30" height="8" rx="2" fill="#E2E8F0" />
            <rect x="3" y="55" width="30" height="8" rx="2" fill="#E2E8F0" />
            <rect x="3" y="66" width="30" height="8" rx="2" fill="#A78BFA" />
            <rect x="3" y="77" width="30" height="8" rx="2" fill="#E2E8F0" />
            <rect x="3" y="88" width="30" height="8" rx="2" fill="#E2E8F0" />
            <rect x="27" y="141" width="6" height="6" rx="3" fill="#A78BFA" />
            <rect x="45" y="26" width="30" height="28" rx="4" fill="#E2E8F0" />
            <rect x="78" y="26" width="30" height="28" rx="4" fill="#F1F5F9" />
            <rect x="111" y="26" width="30" height="28" rx="4" fill="#E2E8F0" />
            <rect x="45" y="57" width="30" height="28" rx="4" fill="#CBD5E1" />
            <rect x="78" y="57" width="30" height="28" rx="4" fill="#E2E8F0" />
            <rect x="111" y="57" width="30" height="28" rx="4" fill="#DDD6FE" />
            <rect x="45" y="88" width="30" height="28" rx="4" fill="#E2E8F0" />
            <rect x="78" y="88" width="30" height="28" rx="4" fill="#CBD5E1" />
            <rect x="111" y="88" width="30" height="28" rx="4" fill="#CBD5E1" />
            <rect x="45" y="119" width="30" height="28" rx="4" fill="#DDD6FE" />
            <rect x="78" y="119" width="30" height="28" rx="4" fill="#E2E8F0" />
            <rect x="111" y="119" width="30" height="28" rx="4" fill="#DDD6FE" />
          </g>
          <defs>
            <clipPath id="clip0_4_306">
              <rect width="150" height="150" rx="12" fill="white" />
            </clipPath>
          </defs>
        </svg>
      );
      break;
  }
  return (
    <div
      className={cx(
        `rounded-[16px] shadow-lg hover:scale-105 cursor-pointer transition-[transform,bottom,border-color,border-width] duration-300 border-4 flex justify-center items-center`,
        raised
          ? `animate-[hover_3s_ease-in-out_infinite] border-green-300`
          : `border-red-400`,
        className,
      )}
      style={{
        bottom: `${raised ? (bottom + 80) * 4 : bottom * 4}px`,
      }}
      onClick={() => {
        setAllowed(!allowed);
      }}
    >
      <div
        className={cx(
          `absolute left-0 top-0 w-full h-full bg-red-300/10 rounded-[12px] transition-[opacity,backdrop-filter] duration-1000`,
          raised ? `opacity-0 backdrop-blur-none` : `opacity-100 backdrop-blur-sm`,
        )}
      />
      <BanIcon
        className={cx(
          `absolute w-32 h-32 text-red-400 transition-opacity duration-300`,
          raised && `opacity-0`,
        )}
        strokeWidth={1.5}
      />
      <div
        className={cx(
          `bg-green-500 w-7 h-7 rounded-full flex justify-center items-center absolute right-3 -top-3 shadow-md transition-opacity duration-300`,
          raised ? `opacity-100` : `opacity-0`,
        )}
      >
        <CheckIcon className="w-5 text-white" />
      </div>
      {graphic}
    </div>
  );
};

export default WebsiteGraphic;
