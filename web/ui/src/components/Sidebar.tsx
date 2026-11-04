import cx from 'clsx';
import { type LucideIcon } from 'lucide-react';
import React from 'react';
import HStack from '../primitives/HStack';
import VStack from '../primitives/VStack';
import Button from './Button';

interface Props {
  children: React.ReactNode;
  logoUrl: string;
  logoWidth: number;
  bottomContent?: React.ReactNode;
  footer?: React.ReactNode;
  bottomButton?: {
    text: string;
    href: string;
    icon: LucideIcon;
  };
}

const Sidebar: React.FC<Props> = ({
  children,
  logoUrl,
  logoWidth,
  bottomContent,
  footer,
  bottomButton,
}) => {
  const scrollRef = React.useRef<HTMLDivElement>(null);
  const [moreBelow, setMoreBelow] = React.useState(false);

  React.useEffect(() => {
    const element = scrollRef.current;
    if (!element) return;
    const update = (): void =>
      setMoreBelow(element.scrollTop + element.clientHeight < element.scrollHeight - 1);
    update();
    const observer = new ResizeObserver(update);
    observer.observe(element);
    if (element.firstElementChild) observer.observe(element.firstElementChild);
    element.addEventListener(`scroll`, update, { passive: true });
    return () => {
      observer.disconnect();
      element.removeEventListener(`scroll`, update);
    };
  }, []);

  return (
    <div className="sticky top-0 flex h-dvh w-68 shrink-0 flex-col overflow-y-clip border-r border-stone-300/80 bg-stone-50 min-[940px]:border-stone-200">
      <div
        ref={scrollRef}
        className={cx(
          `relative z-10 min-h-0 flex-grow overflow-y-auto overscroll-contain pt-5 pb-3 pl-5 pr-5 [scrollbar-width:none] min-[940px]:-mr-[3px] min-[940px]:pr-[23px] [&::-webkit-scrollbar]:hidden`,
          moreBelow &&
            `[mask-image:linear-gradient(to_bottom,black_calc(100%-1.5rem),transparent)]`,
        )}
      >
        <VStack justify="between" gap={9} className="min-h-full">
          <VStack gap={9}>
            <div>
              <img src={logoUrl} alt="Logo" width={logoWidth} />
            </div>
            <VStack gap={7}>{children}</VStack>
          </VStack>
          {bottomContent && <VStack gap={4}>{bottomContent}</VStack>}
        </VStack>
      </div>
      {(footer || bottomButton) && (
        <VStack gap={4} className="shrink-0 px-5 pt-1 pb-5">
          {footer}
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
      )}
    </div>
  );
};

export default Sidebar;
