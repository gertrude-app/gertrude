import cx from 'clsx';
import { type LucideIcon } from 'lucide-react';
import React from 'react';
import Button from './Button';

interface Props {
  icon: LucideIcon;
  title: string;
  description: React.ReactNode;
  button?: {
    text: string;
    icon?: LucideIcon;
    variant?: `primary` | `default` | `ghost` | `destructive`;
  } & (
    | {
        type: `link`;
        href: string;
      }
    | {
        type: `button`;
        onClick: () => void;
      }
  );
  className?: string;
}

const EmptyState: React.FC<Props> = ({
  icon: Icon,
  title,
  description,
  button,
  className,
}) => (
  <div
    className={cx(
      `flex flex-col items-center rounded-xl bg-stone-50 py-6 bg-dots border border-stone-200`,
      className,
    )}
  >
    <Icon className="h-6 w-6 text-stone-600" />
    <span className="mt-2 font-medium text-stone-900">{title}</span>
    <span className="mb-4 text-sm text-stone-500">{description}</span>
    {button &&
      (button.type === `link` ? (
        <Button
          type="link"
          href={button.href}
          icon={button.icon}
          variant={button.variant}
        >
          {button.text}
        </Button>
      ) : (
        <Button
          type="button"
          onClick={button.onClick}
          icon={button.icon}
          variant={button.variant}
        >
          {button.text}
        </Button>
      ))}
  </div>
);

export default EmptyState;
