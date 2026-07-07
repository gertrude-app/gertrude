import cx from 'clsx';
import { CircleAlertIcon, InfoIcon, type LucideIcon } from 'lucide-react';
import React from 'react';
import HStack from '../primitives/HStack';
import Text from '../primitives/Text';

export type BannerVariant = `neutral` | `warning` | `error`;

export interface BannerProps {
  children: React.ReactNode;
  variant?: BannerVariant;
  className?: string;
}

type VariantStyles = {
  container: string;
  icon: string;
  Icon: LucideIcon;
};

const variantStyles: Record<BannerVariant, VariantStyles> = {
  neutral: {
    container: `border-stone-300/80 bg-stone-100/80 text-stone-700`,
    icon: `text-stone-500`,
    Icon: InfoIcon,
  },
  warning: {
    container: `border-amber-400/80 bg-amber-200/30 text-amber-800`,
    icon: `text-amber-800/60`,
    Icon: InfoIcon,
  },
  error: {
    container: `border-red-500/80 bg-red-100/70 text-red-950`,
    icon: `text-red-800`,
    Icon: CircleAlertIcon,
  },
};

const Banner: React.FC<BannerProps> = ({ children, variant = `neutral`, className }) => {
  const styles = variantStyles[variant];
  const Icon = styles.Icon;

  return (
    <HStack
      align="start"
      gap={3}
      className={cx(`rounded-xl border p-3`, styles.container, className)}
    >
      <Icon className={cx(`h-5 w-5 shrink-0`, styles.icon)} />
      <Text
        as="div"
        variant="body"
        className="leading-5 [&_strong]:font-semibold"
        style={{ color: `inherit` }}
      >
        {children}
      </Text>
    </HStack>
  );
};

export default Banner;
