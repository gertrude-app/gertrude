'use client';

import { DotIcon } from 'lucide-react';
import { usePathname } from 'next/navigation';
import FancyLink from 'components/FancyLink';
import React from 'react';
import Link from 'next/link';
import cx from 'classnames';
import { Logo } from '@shared/components';

interface Props {
  open: boolean;
  setOpen: (open: boolean) => void;
}

const Sidebar: React.FC<Props> = ({ open, setOpen }) => (
  <nav
    className={cx(
      `w-80 flex pl-4 py-4 h-screen fixed lg:bg-gradient-to-r lg:from-violet-200 lg:to-white z-10 transition-[margin-left] duration-300`,
      open ? `ml-0` : `-ml-96 lg:ml-0`,
    )}
  >
    <div className="bg-white rounded-3xl lg:rounded-r-none p-4 overflow-scroll py-8 shadow-lg lg:shadow-none flex-grow flex flex-col justify-between">
      <div>
        <Link href="/">
          <Logo className="ml-4" />
        </Link>
        <div className="mt-10 flex flex-col">
          <SidebarLink slug="getting-started" title="Getting Started" setOpen={setOpen} />
          <SidebarLink slug="faqs" title="Frequently Asked Questions" setOpen={setOpen} />
          <SidebarLink slug="troubleshooting" title="Troubleshooting" setOpen={setOpen} />
          <SidebarLink
            slug="unblocking-guide"
            title="Unblocking Guide"
            setOpen={setOpen}
          />
          <SidebarLink
            slug="keeping-children-safe"
            title="Keeping Children Safe"
            setOpen={setOpen}
          />
        </div>
      </div>
      <div className="flex flex-col gap-4">
        <FancyLink type="link" href="https://parents.gertrude.app" size="sm">
          Log in
        </FancyLink>
        <FancyLink
          type="link"
          href="https://parents.gertrude.app/signup"
          size="sm"
          color="primary"
        >
          Sign up
        </FancyLink>
      </div>
    </div>
  </nav>
);

export default Sidebar;

interface SidebarLinkProps {
  slug: string;
  title: string;
  setOpen: (open: boolean) => void;
}

const SidebarLink: React.FC<SidebarLinkProps> = ({ slug, title, setOpen }) => {
  const path = usePathname();
  const active = path.includes(slug);

  return (
    <Link
      href={`/docs/${slug}`}
      className={cx(
        `hover:bg-slate-50 rounded-2xl px-3 py-2 leading-snug flex items-start transition-colors duration-200 gap-1`,
        active
          ? `text-slate-800 font-semibold bg-violet-50 hover:!bg-violet-100`
          : `text-slate-600 font-medium`,
      )}
      onClick={() => setOpen(false)}
    >
      <DotIcon
        strokeWidth={6}
        className={cx(`shrink-0 mt-[2px]`, active ? `text-violet-500` : `text-slate-300`)}
      />
      <span className="text-lg">{title}</span>
    </Link>
  );
};
