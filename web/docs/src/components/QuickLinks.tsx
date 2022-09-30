import React from 'react';
import Link from 'next/link';
import Icon from '@/components/Icon';

interface Props {
  title: string;
  description: string;
  href: string;
  icon: React.ComponentProps<typeof Icon>['icon'];
}

export const QuickLink: React.FC<Props> = ({ title, description, href, icon }) => (
  <div className="group relative rounded-xl border border-slate-200 dark:border-slate-800">
    <div className="absolute -inset-px rounded-xl border-2 border-transparent opacity-0 [background:linear-gradient(var(--quick-links-hover-bg,theme(colors.violet.50)),var(--quick-links-hover-bg,theme(colors.violet.50)))_padding-box,linear-gradient(to_top,theme(colors.indigo.400),theme(colors.cyan.400),theme(colors.violet.500))_border-box] group-hover:opacity-100 dark:[--quick-links-hover-bg:theme(colors.slate.800)]" />
    <div className="relative overflow-hidden rounded-xl p-6">
      <Icon color="blue" icon={icon} className="h-8 w-8" />
      <h2 className="font-display mt-4 text-base text-slate-900 dark:text-white">
        <Link href={href}>
          <span className="absolute -inset-px rounded-xl" />
          {title}
        </Link>
      </h2>
      <p className="mt-1 text-sm text-slate-700 dark:text-slate-400">{description}</p>
    </div>
  </div>
);

export const QuickLinks: React.FC<{ children: React.ReactNode }> = ({ children }) => (
  <div className="not-prose my-12 grid grid-cols-1 gap-6 sm:grid-cols-2">{children}</div>
);
