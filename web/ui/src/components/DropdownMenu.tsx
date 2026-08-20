import { Menu } from '@base-ui/react/menu';
import cx from 'clsx';
import React from 'react';
import { useOverlayPortalContainer } from './OverlayPortalContext';

interface Props {
  trigger: React.ReactNode;
  children: React.ReactNode;
  searchable?: boolean;
  disabled?: boolean;
  contentClassName?: string;
  open?: boolean;
  defaultOpen?: boolean;
  onOpenChange?: (open: boolean) => void;
}

type FilterableChildProps = {
  title?: unknown;
  description?: unknown;
  active?: boolean;
};

const menuNavigationKeys = [`ArrowDown`, `ArrowUp`, `Home`, `End`];

const filterChildren = (children: React.ReactNode, query: string): React.ReactNode[] => {
  const childArray = React.Children.toArray(children);

  if (!query) {
    return childArray;
  }

  return childArray.filter((child) => {
    if (!React.isValidElement<FilterableChildProps>(child)) {
      return true;
    }

    const searchableText = [child.props.title, child.props.description]
      .filter((value): value is string => typeof value === `string`)
      .join(` `)
      .toLowerCase();

    return searchableText ? searchableText.includes(query) : true;
  });
};

const DropdownMenu: React.FC<Props> = ({
  trigger,
  children,
  searchable,
  disabled,
  contentClassName = `w-60`,
  open,
  defaultOpen = false,
  onOpenChange,
}) => {
  const [internalOpen, setInternalOpen] = React.useState(defaultOpen);
  const menuOpen = open ?? internalOpen;
  const [searchQuery, setSearchQuery] = React.useState(``);
  const [activeIndex, setActiveIndex] = React.useState(-1);
  const searchInputRef = React.useRef<HTMLInputElement>(null);
  const overlayPortalContainer = useOverlayPortalContainer();
  const normalizedSearchQuery = searchQuery.trim().toLowerCase();
  const visibleChildren = searchable
    ? filterChildren(children, normalizedSearchQuery)
    : React.Children.toArray(children);
  const renderedChildren = searchable
    ? visibleChildren.map((child, index) =>
        React.isValidElement<FilterableChildProps>(child)
          ? React.cloneElement(child, { active: index === activeIndex })
          : child,
      )
    : visibleChildren;
  const triggerElement = React.isValidElement(trigger) ? trigger : undefined;

  React.useEffect(() => {
    if (!menuOpen || !searchable) {
      return;
    }

    const animationFrame = window.requestAnimationFrame(() => {
      searchInputRef.current?.focus();
    });

    return () => window.cancelAnimationFrame(animationFrame);
  }, [menuOpen, searchable]);

  React.useEffect(() => {
    if (!searchable || visibleChildren.length === 0) {
      setActiveIndex(-1);
      return;
    }

    setActiveIndex((currentIndex) =>
      currentIndex === -1 || currentIndex >= visibleChildren.length ? 0 : currentIndex,
    );
  }, [searchable, visibleChildren.length]);

  const moveActiveItem = (key: string): void => {
    if (visibleChildren.length === 0) {
      return;
    }

    setActiveIndex((currentIndex) => {
      if (key === `Home`) {
        return 0;
      }

      if (key === `End`) {
        return visibleChildren.length - 1;
      }

      if (key === `ArrowUp`) {
        return currentIndex <= 0 ? visibleChildren.length - 1 : currentIndex - 1;
      }

      return currentIndex === -1 || currentIndex === visibleChildren.length - 1
        ? 0
        : currentIndex + 1;
    });
  };

  const selectActiveItem = (): void => {
    const menuItems = Array.from(
      document.querySelectorAll<HTMLElement>(
        `[role="menuitem"], [role="menuitemcheckbox"], [role="menuitemradio"]`,
      ),
    );
    const activeMenuItem = menuItems[activeIndex];

    if (!activeMenuItem) {
      return;
    }

    activeMenuItem.click();
  };
  const setMenuOpen = (nextOpen: boolean): void => {
    if (open === undefined) {
      setInternalOpen(nextOpen);
    }

    onOpenChange?.(nextOpen);

    if (!nextOpen) {
      setSearchQuery(``);
      setActiveIndex(-1);
    }
  };

  return (
    <Menu.Root
      open={menuOpen}
      onOpenChange={(nextOpen) => {
        if (disabled) {
          setMenuOpen(false);
          return;
        }

        setMenuOpen(nextOpen);
      }}
      disabled={disabled}
      modal={false}
    >
      {triggerElement ? (
        <Menu.Trigger render={triggerElement} disabled={disabled} />
      ) : (
        <Menu.Trigger disabled={disabled}>{trigger}</Menu.Trigger>
      )}
      <Menu.Portal container={overlayPortalContainer ?? undefined}>
        <Menu.Positioner sideOffset={4} align="center" className="z-[60]">
          <Menu.Popup
            className={cx(
              `z-[60] mx-1 flex flex-col gap-1 rounded-xl border border-stone-200 bg-white p-1 shadow-md shadow-stone-300/50 outline-none select-none`,
              contentClassName,
            )}
          >
            {searchable && (
              <input
                ref={searchInputRef}
                value={searchQuery}
                className="outline-none placeholder:text-stone-400/70 border border-stone-200 text-sm px-2 py-1.25 rounded-lg bg-stone-100/50"
                placeholder="Type to search..."
                onChange={(event) => setSearchQuery(event.target.value)}
                onKeyDown={(event) => {
                  if (menuNavigationKeys.includes(event.key)) {
                    event.preventDefault();
                    event.stopPropagation();
                    moveActiveItem(event.key);
                    return;
                  }

                  if (event.key === `Enter`) {
                    event.preventDefault();
                    event.stopPropagation();
                    selectActiveItem();
                    return;
                  }

                  if (event.key !== `Escape`) {
                    event.stopPropagation();
                  }
                }}
              />
            )}
            <div>{renderedChildren.length > 0 ? renderedChildren : null}</div>
          </Menu.Popup>
        </Menu.Positioner>
      </Menu.Portal>
    </Menu.Root>
  );
};

export default DropdownMenu;
