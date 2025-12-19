import Link from 'next/link';
import React from 'react';
import Icon from './Icon';

interface Props {
  title: string;
  description: string;
  href: string;
  icon: React.ComponentProps<typeof Icon>[`icon`];
}

export const QuickLink: React.FC<Props> = ({ title, description, href, icon }) => (
  <div className="group relative rounded-xl border border-slate-800">
    <div className="absolute -inset-px rounded-xl border-2 border-transparent opacity-0 group-hover:opacity-100 [--quick-links-hover-bg:theme(colors.slate.800)]" />
    <div className="relative overflow-hidden rounded-xl p-6">
      <Icon color="blue" icon={icon} className="h-8 w-8" />
      <h2 className="font-lexend mt-4 text-base text-white">
        <Link href={href}>
          <span className="absolute -inset-px rounded-xl" />
          {title}
        </Link>
      </h2>
      <p className="mt-1 text-sm text-slate-400">{description}</p>
    </div>
  </div>
);

export const QuickLinks: React.FC<{ children: React.ReactNode }> = ({ children }) => (
  <div className="not-prose my-12 grid grid-cols-1 gap-6 sm:grid-cols-2">{children}</div>
);
