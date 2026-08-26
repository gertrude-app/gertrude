import cx from 'clsx';
import { type LucideIcon } from 'lucide-react';
import React from 'react';
import Text from '../primitives/Text';
import VStack from '../primitives/VStack';
import Button from './Button';

interface Props {
  icon: LucideIcon;
  title: string;
  description: React.ReactNode;
  button?: {
    text: string;
    icon?: LucideIcon;
    variant?: `primary` | `default` | `ghost` | `destructive`;
    loading?: boolean;
  } & (
    | {
        type: `link`;
        href: string;
        target?: string;
        rel?: string;
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
  <VStack
    align="center"
    justify="center"
    className={cx(
      `rounded-xl bg-stone-50 px-6 py-6 text-center bg-dots border border-stone-200`,
      className,
    )}
  >
    <Icon className="h-6 w-6 text-stone-600" />
    <Text variant="bodyStrong" className="mt-2 text-base">
      {title}
    </Text>
    <Text variant="bodyMuted" className={cx(`mt-0.5`, button && `mb-4`)}>
      {description}
    </Text>
    {button &&
      (button.type === `link` ? (
        <Button
          type="link"
          href={button.href}
          target={button.target}
          rel={button.rel}
          icon={button.icon}
          variant={button.variant}
          loading={button.loading}
        >
          {button.text}
        </Button>
      ) : (
        <Button
          type="button"
          onClick={button.onClick}
          icon={button.icon}
          variant={button.variant}
          loading={button.loading}
        >
          {button.text}
        </Button>
      ))}
  </VStack>
);

export default EmptyState;
