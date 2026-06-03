import { type LucideIcon } from 'lucide-react';
import React from 'react';
import Button from '../Button';

interface Props {
  children: React.ReactNode;
  logoUrl: string;
  logoWidth: number;
  bottomButton?: {
    text: string;
    href: string;
    icon: LucideIcon;
  };
}

const Sidebar: React.FC<Props> = ({ children, logoUrl, logoWidth, bottomButton }) => (
  <div className="sticky top-0 flex h-dvh w-68 shrink-0 flex-col justify-between overflow-y-auto border-r border-stone-300/80 bg-stone-50 p-5 min-[940px]:overflow-visible min-[940px]:border-stone-200">
    <div className="flex flex-col gap-9">
      <div>
        <img src={logoUrl} alt="Logo" width={logoWidth} />
      </div>
      <div className="flex flex-col gap-7">{children}</div>
    </div>
    {bottomButton && (
      <div className="flex">
        <Button
          type="link"
          href={bottomButton.href}
          size="small"
          icon={bottomButton.icon}
        >
          {bottomButton.text}
        </Button>
      </div>
    )}
  </div>
);

export default Sidebar;
