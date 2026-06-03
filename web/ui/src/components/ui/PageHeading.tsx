import { EllipsisIcon, type LucideIcon } from 'lucide-react';
import React from 'react';
import Button from './Button';
import DropdownMenu from './dropdown-menu/DropdownMenu';
import DropdownMenuItem from './dropdown-menu/DropdownMenuItem';

interface Props {
  title: string;
  subtitle?: string;
  buttons?: Array<{
    text: string;
    onClick: () => void;
    variant?: `primary` | `secondary`;
    icon?: LucideIcon;
  }>;
  breadcrumbs?: Array<{ text: string; href: string }>;
}

const PageHeading: React.FC<Props> = ({
  title,
  subtitle,
  buttons = [],
  breadcrumbs = [],
}) => (
  <div className="@2xl/main:border-b border-stone-200/60 pb-4">
    {breadcrumbs.length > 0 && (
      <nav aria-label="Breadcrumb" className="mb-2">
        <ol className="flex flex-wrap items-center gap-1.5 text-sm text-stone-500">
          {breadcrumbs.map((breadcrumb, index) => (
            <li
              key={`${breadcrumb.href}-${breadcrumb.text}`}
              className="flex items-center gap-1.5"
            >
              {index > 0 && <span className="text-stone-300">/</span>}
              <a
                href={breadcrumb.href}
                className="rounded-md px-1.5 py-0.5 -mx-1.5 text-stone-500 transition-colors hover:bg-stone-100 hover:text-stone-900 focus-visible:bg-stone-100 focus-visible:text-stone-900 focus-visible:outline-none"
              >
                {breadcrumb.text}
              </a>
            </li>
          ))}
        </ol>
      </nav>
    )}
    <div className="flex justify-between items-end">
      <div className="flex flex-col gap-2">
        <h1 className="text-3xl font-medium text-stone-900 flex-grow @2xl/main:-mb-2">
          {title}
        </h1>
        {subtitle && <h2 className="text-stone-600">{subtitle}</h2>}
      </div>
      {buttons.length > 0 && (
        <>
          <div className="flex @2xl/main:hidden">
            <DropdownMenu
              trigger={<Button type="button" onClick={() => {}} icon={EllipsisIcon} />}
            >
              {buttons.map((button) => (
                <DropdownMenuItem
                  key={button.text}
                  title={button.text}
                  icon={button.icon}
                  onSelect={button.onClick}
                />
              ))}
            </DropdownMenu>
          </div>
          <div className="hidden @2xl/main:flex gap-2">
            {buttons.map((button) => (
              <Button
                key={button.text}
                type="button"
                variant={button.variant === `primary` ? `primary` : `default`}
                onClick={button.onClick}
                icon={button.icon}
              >
                {button.text}
              </Button>
            ))}
          </div>
        </>
      )}
    </div>
  </div>
);

export default PageHeading;
