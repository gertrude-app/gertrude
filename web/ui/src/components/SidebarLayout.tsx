import cx from 'clsx';
import { SidebarIcon } from 'lucide-react';
import React, { useCallback, useEffect, useMemo, useState } from 'react';
import Button from './Button';
import { SidebarContext } from './SidebarContext';

interface Props {
  content: React.ReactNode;
  children: React.ReactNode;
}

const SidebarLayout: React.FC<Props> = ({ content, children }) => {
  const [open, setOpen] = useState(false);
  const close = useCallback(() => setOpen(false), []);
  const sidebarContext = useMemo(() => ({ close }), [close]);

  useEffect(() => {
    if (!open) {
      return;
    }

    const { body, documentElement } = document;
    const scrollY = window.scrollY;
    const previousBodyPosition = body.style.position;
    const previousBodyTop = body.style.top;
    const previousBodyLeft = body.style.left;
    const previousBodyRight = body.style.right;
    const previousBodyWidth = body.style.width;
    const previousBodyOverflow = body.style.overflow;
    const previousDocumentOverflow = documentElement.style.overflow;

    body.style.position = `fixed`;
    body.style.top = `-${scrollY}px`;
    body.style.left = `0`;
    body.style.right = `0`;
    body.style.width = `100%`;
    body.style.overflow = `hidden`;
    documentElement.style.overflow = `hidden`;

    return () => {
      body.style.position = previousBodyPosition;
      body.style.top = previousBodyTop;
      body.style.left = previousBodyLeft;
      body.style.right = previousBodyRight;
      body.style.width = previousBodyWidth;
      body.style.overflow = previousBodyOverflow;
      documentElement.style.overflow = previousDocumentOverflow;
      window.scrollTo(0, scrollY);
    };
  }, [open]);

  return (
    <SidebarContext.Provider value={sidebarContext}>
      <div className="flex min-h-screen relative">
        <div className="hidden min-[940px]:block">{children}</div>
        <div
          className={cx(
            `fixed inset-0 z-50 bg-stone-200/80 transition-[opacity,filter] duration-150 min-[940px]:hidden`,
            open ? `opacity-100 backdrop-blur` : `pointer-events-none opacity-0`,
          )}
          onClick={close}
        />
        <div
          className={cx(
            `fixed left-0 top-0 z-100 h-dvh w-68 overflow-y-auto overscroll-contain bg-white shadow-xl transition-transform duration-150 min-[940px]:hidden`,
            open ? `translate-x-0` : `-translate-x-68`,
          )}
        >
          {children}
        </div>
        <main className="flex-grow">
          <div className="px-3 min-[32rem]:px-4 min-[36rem]:px-8 min-[48rem]:px-12 py-3 min-[32rem]:py-4 min-[36rem]:py-6 min-[940px]:hidden block">
            <Button type="button" onClick={() => setOpen(!open)} icon={SidebarIcon} />
          </div>
          <div>{content}</div>
        </main>
      </div>
    </SidebarContext.Provider>
  );
};

export default SidebarLayout;
