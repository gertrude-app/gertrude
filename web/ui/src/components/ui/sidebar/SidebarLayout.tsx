import React, { useCallback, useMemo, useState } from 'react';
import cx from 'clsx';
import Button from '../Button';
import { SidebarIcon } from 'lucide-react';
import { SidebarContext } from './SidebarContext';

interface Props {
  content: React.ReactNode;
  children: React.ReactNode;
}

const SidebarLayout: React.FC<Props> = ({ content, children }) => {
  const [open, setOpen] = useState(false);
  const close = useCallback(() => setOpen(false), []);
  const sidebarContext = useMemo(() => ({ close }), [close]);

  return (
    <SidebarContext.Provider value={sidebarContext}>
      <div className="flex min-h-screen relative">
        <div className="hidden min-[940px]:block">{children}</div>
        <div
          className={cx(
            'absolute inset-0 bg-stone-200/80 z-50 transition-[opacity,filter] duration-150 min-[940px]:hidden',
            open ? 'opacity-100 backdrop-blur' : 'opacity-0 pointer-events-none',
          )}
          onClick={close}
        />
        <div
          className={cx(
            'absolute left-0 top-0 h-screen w-64 z-100 bg-white min-[940px]:hidden transition-transform duration-150 shadow-xl',
            open ? 'translate-x-0' : '-translate-x-68',
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
