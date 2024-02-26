import Link from 'next/link';
import React from 'react';
import cx from 'classnames';
import type { ArrowUpIcon } from 'lucide-react';
import { axiforma } from '../lib/fonts';

type LucideIcon = typeof ArrowUpIcon;

interface FancyLinkProps {
  href: string;
  children: React.ReactNode;
  size?: 'lg' | 'sm';
  color?: 'primary' | 'secondary';
  Icon?: LucideIcon;
  inverted?: boolean;
  className?: string;
}

const FancyLink: React.FC<FancyLinkProps> = ({
  href,
  children,
  size = `lg`,
  color = `primary`,
  Icon,
  inverted = false,
  className,
}) => (
  <Link href={href} className={cx(`relative group select-none`, axiforma, className)}>
    {color === `primary` && (
      <div
        className={cx(`absolute w-full h-full bg-black`, {
          'bg-gradient-to-r from-violet-700 to-fuchsia-700': !inverted,
          'bg-white/50': inverted,
          'rounded-3xl translate-y-2': size === `lg`,
          'rounded-2xl translate-y-1.5': size === `sm`,
        })}
      ></div>
    )}
    <div
      className={cx(
        `flex items-center justify-center relative transition-[transform,background-color] duration-200 overflow-hidden`,
        {
          'group-hover:-translate-y-0.5': color === `primary`,
          'group-active:translate-y-0.5': color === `primary`,
          'bg-white': inverted && color === `primary`,
          'bg-white/10 group-hover:bg-white/20 group-active:bg-white/30 group-active:scale-[98%]':
            inverted && color === `secondary`,
          'bg-gradient-to-r from-violet-500 to-fuchsia-500':
            !inverted && color === `primary`,
          'bg-violet-100 group-hover:bg-violet-200 group-active:bg-violet-300 group-active:scale-[98%]':
            !inverted && color === `secondary`,
          'px-8 py-4 rounded-3xl gap-3': size === `lg`,
          'px-6 py-3 rounded-2xl gap-2': size === `sm`,
        },
      )}
    >
      {color === `primary` && (
        <div
          className={cx(
            `absolute -left-16 group-hover:left-20 -top-5 rotate-12 h-24 w-32 bg-gradient-to-r from-transparent to-transparent transition-[left,opacity] duration-200 group-active:opacity-0`,
            inverted ? `via-white/40` : `via-white/10`,
          )}
        />
      )}
      {Icon && (
        <Icon
          size={size === `lg` ? 30 : 25}
          className={cx(``, {
            'text-white':
              (!inverted && color === `primary`) || (inverted && color === `secondary`),
            'text-violet-600':
              (!inverted && color === `secondary`) || (inverted && color === `primary`),
          })}
        />
      )}
      <span
        className={cx(`font-semibold`, {
          'bg-gradient-to-r from-violet-600 to-fuchsia-500 bg-clip-text text-transparent':
            (!inverted && color === `secondary`) || (inverted && color === `primary`),
          'text-white':
            (!inverted && color === `primary`) || (inverted && color === `secondary`),
          'text-2xl -mb-1': size === `lg`,
          'text-xl -mb-0.5': size === `sm`,
        })}
      >
        {children}
      </span>
    </div>
  </Link>
);

export default FancyLink;
