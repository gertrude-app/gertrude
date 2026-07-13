import { Link, useNavigate } from '@tanstack/react-router';
import { EllipsisIcon, type LucideIcon } from 'lucide-react';
import React from 'react';
import Divider from '../primitives/Divider';
import HStack from '../primitives/HStack';
import Text from '../primitives/Text';
import VStack from '../primitives/VStack';
import Button from './Button';
import DropdownMenu from './DropdownMenu';
import DropdownMenuItem from './DropdownMenuItem';

type PageHeadingButtonBase = {
  text: string;
  variant?: `primary` | `secondary`;
  icon?: LucideIcon;
};

type PageHeadingButton =
  | (PageHeadingButtonBase & { onClick: () => void; href?: never })
  | (PageHeadingButtonBase & { href: string; onClick?: never });

interface Props {
  title: string;
  subtitle?: string;
  buttons?: PageHeadingButton[];
  breadcrumbs?: Array<{ text: string; href: string }>;
}

const isLinkButton = (
  button: PageHeadingButton,
): button is PageHeadingButtonBase & { href: string; onClick?: never } =>
  `href` in button;

const isInternalHref = (href: string): boolean =>
  href.startsWith(`/`) && !href.startsWith(`//`);

const PageHeading: React.FC<Props> = ({
  title,
  subtitle,
  buttons = [],
  breadcrumbs = [],
}) => {
  const navigate = useNavigate();

  const handleDropdownSelect = (button: PageHeadingButton): void => {
    if (isLinkButton(button)) {
      if (isInternalHref(button.href)) {
        void navigate({ to: button.href });
        return;
      }

      window.location.href = button.href;
      return;
    }

    button.onClick();
  };

  return (
    <div className="pb-4 @2xl/main:pb-0">
      {breadcrumbs.length > 0 && (
        <nav aria-label="Breadcrumb" className="mb-2">
          <HStack as="ol" wrap gap={1.5}>
            {breadcrumbs.map((breadcrumb, index) => (
              <HStack as="li" key={`${breadcrumb.href}-${breadcrumb.text}`} gap={1.5}>
                {index > 0 && (
                  <Text variant="bodyMuted" className="!text-stone-300">
                    /
                  </Text>
                )}
                {isInternalHref(breadcrumb.href) ? (
                  <Text
                    as={Link}
                    to={breadcrumb.href}
                    variant="bodyMuted"
                    className="-mx-1.5 rounded-md px-1.5 py-0.5 transition-colors hover:bg-stone-100 hover:!text-stone-900 focus-visible:bg-stone-100 focus-visible:!text-stone-900 focus-visible:outline-none"
                  >
                    {breadcrumb.text}
                  </Text>
                ) : (
                  <Text
                    as="a"
                    href={breadcrumb.href}
                    variant="bodyMuted"
                    className="-mx-1.5 rounded-md px-1.5 py-0.5 transition-colors hover:bg-stone-100 hover:!text-stone-900 focus-visible:bg-stone-100 focus-visible:!text-stone-900 focus-visible:outline-none"
                  >
                    {breadcrumb.text}
                  </Text>
                )}
              </HStack>
            ))}
          </HStack>
        </nav>
      )}
      <HStack justify="between" align="end">
        <VStack gap={2}>
          <Text as="h1" variant="display" className="flex-grow @2xl/main:-mb-2">
            {title}
          </Text>
          {subtitle && (
            <Text as="h2" variant="bodyMuted" className="text-base">
              {subtitle}
            </Text>
          )}
        </VStack>
        {buttons.length > 0 && (
          <>
            <HStack hideAbove="@2xl/main">
              <DropdownMenu
                trigger={<Button type="button" onClick={() => {}} icon={EllipsisIcon} />}
              >
                {buttons.map((button) => (
                  <DropdownMenuItem
                    key={button.text}
                    title={button.text}
                    icon={button.icon}
                    onSelect={() => handleDropdownSelect(button)}
                  />
                ))}
              </DropdownMenu>
            </HStack>
            <HStack hideBelow="@2xl/main" gap={2}>
              {buttons.map((button) =>
                isLinkButton(button) ? (
                  <Button
                    key={button.text}
                    type="link"
                    href={button.href}
                    variant={button.variant === `primary` ? `primary` : `default`}
                    icon={button.icon}
                  >
                    {button.text}
                  </Button>
                ) : (
                  <Button
                    key={button.text}
                    type="button"
                    variant={button.variant === `primary` ? `primary` : `default`}
                    onClick={button.onClick}
                    icon={button.icon}
                  >
                    {button.text}
                  </Button>
                ),
              )}
            </HStack>
          </>
        )}
      </HStack>
      <Divider hideBelow="@2xl/main" className="mt-4 !bg-stone-200/60" />
    </div>
  );
};

export default PageHeading;
