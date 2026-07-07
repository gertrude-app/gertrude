import { type LucideIcon } from 'lucide-react';
import React from 'react';
import HStack from '../primitives/HStack';
import VStack from '../primitives/VStack';
import Button from './Button';

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
  <VStack
    justify="between"
    className="sticky top-0 h-dvh w-68 shrink-0 overflow-y-auto border-r border-stone-300/80 bg-stone-50 p-5 min-[940px]:overflow-visible min-[940px]:border-stone-200"
  >
    <VStack gap={9}>
      <div>
        <img src={logoUrl} alt="Logo" width={logoWidth} />
      </div>
      <VStack gap={7}>{children}</VStack>
    </VStack>
    {bottomButton && (
      <HStack>
        <Button
          type="link"
          href={bottomButton.href}
          size="small"
          icon={bottomButton.icon}
        >
          {bottomButton.text}
        </Button>
      </HStack>
    )}
  </VStack>
);

export default Sidebar;
