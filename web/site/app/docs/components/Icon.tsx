import { useId } from 'react';
import cx from 'classnames';

import PluginsIcon from './icons/PluginsIcon';
import PresetsIcon from './icons/PresetsIcon';
import WarningIcon from './icons/WarningIcon';
import InstallationIcon from './icons/InstallationIcon';
import LightbulbIcon from './icons/LightbulbIcon';
import ThemingIcon from './icons/ThemingIcon';

const icons = {
  installation: InstallationIcon,
  presets: PresetsIcon,
  plugins: PluginsIcon,
  theming: ThemingIcon,
  lightbulb: LightbulbIcon,
  warning: WarningIcon,
};

const iconStyles = {
  blue: `[--icon-foreground:theme(colors.slate.900)] [--icon-background:theme(colors.white)]`,
  amber: `[--icon-foreground:theme(colors.amber.900)] [--icon-background:theme(colors.amber.100)]`,
};

type Props = {
  icon: keyof typeof icons;
  className?: string;
  color: 'amber' | 'blue';
};

const Icon: React.FC<Props> = ({ icon, className, color }) => {
  const id = useId();
  const IconComponent = icons[icon];

  return (
    <svg
      aria-hidden="true"
      viewBox="0 0 32 32"
      fill="none"
      className={cx(className, iconStyles[color])}
    >
      <IconComponent id={id} color={color} />
    </svg>
  );
};

export default Icon;

const gradients = {
  blue: [
    { stopColor: `#d946ef`, offset: `.327` },
    { stopColor: `#6366f1`, offset: 1 },
  ],
  amber: [
    { stopColor: `#FDE68A`, offset: `.08` },
    { stopColor: `#F59E0B`, offset: `.837` },
  ],
} as const;

type GradientProps = {
  id: string;
  color: 'blue' | 'amber';
  gradientTransform: string;
};

export const Gradient: React.FC<GradientProps> = ({ id, color, gradientTransform }) => (
  <radialGradient
    cx={0}
    cy={0}
    r={1}
    gradientUnits="userSpaceOnUse"
    id={id}
    color={color}
    gradientTransform={gradientTransform}
  >
    {gradients[color].map((stop: any, stopIndex: any) => (
      <stop key={stopIndex} {...stop} />
    ))}
  </radialGradient>
);

export const LightMode: React.FC<{ children: React.ReactNode }> = ({ children }) => (
  <g className="hidden">{children}</g>
);

export const DarkMode: React.FC<{
  children: React.ReactNode;
  strokeWidth?: number;
  strokeLinecap?: 'round' | 'butt' | 'square' | 'inherit';
  strokeLinejoin?: 'round' | 'miter' | 'bevel' | 'inherit';
  fill?: string;
}> = ({ children, ...props }) => (
  <g className="inline" {...props}>
    {children}
  </g>
);
