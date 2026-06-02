import React from 'react';
import { Menu } from '@base-ui/react/menu';

interface Props {
  trigger: React.ReactNode;
  children: React.ReactNode;
  searchable?: boolean;
  disabled?: boolean;
}

type FilterableChildProps = {
  title?: unknown;
  active?: boolean;
};

const menuNavigationKeys = ['ArrowDown', 'ArrowUp', 'Home', 'End'];

const filterChildren = (children: React.ReactNode, query: string): React.ReactNode[] => {
  const childArray = React.Children.toArray(children);

  if (!query) {
    return childArray;
  }

  return childArray.filter((child) => {
    if (!React.isValidElement<FilterableChildProps>(child)) {
      return true;
    }

    return typeof child.props.title === 'string'
      ? child.props.title.toLowerCase().includes(query)
      : true;
  });
};

const DropdownMenu: React.FC<Props> = ({ trigger, children, searchable, disabled }) => {
  const [open, setOpen] = React.useState(false);
  const [searchQuery, setSearchQuery] = React.useState('');
  const [activeIndex, setActiveIndex] = React.useState(-1);
  const searchInputRef = React.useRef<HTMLInputElement>(null);
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
    if (!open || !searchable) {
      return;
    }

    const animationFrame = window.requestAnimationFrame(() => {
      searchInputRef.current?.focus();
    });

    return () => window.cancelAnimationFrame(animationFrame);
  }, [open, searchable]);

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
      if (key === 'Home') {
        return 0;
      }

      if (key === 'End') {
        return visibleChildren.length - 1;
      }

      if (key === 'ArrowUp') {
        return currentIndex <= 0 ? visibleChildren.length - 1 : currentIndex - 1;
      }

      return currentIndex === -1 || currentIndex === visibleChildren.length - 1
        ? 0
        : currentIndex + 1;
    });
  };

  const selectActiveItem = (): void => {
    const menuItems = Array.from(
      document.querySelectorAll<HTMLElement>('[role="menuitem"]'),
    );
    const activeMenuItem = menuItems[activeIndex];

    if (!activeMenuItem) {
      return;
    }

    activeMenuItem.click();
  };

  return (
    <Menu.Root
      open={open}
      onOpenChange={(nextOpen) => {
        if (disabled) {
          setOpen(false);
          return;
        }

        setOpen(nextOpen);

        if (!nextOpen) {
          setSearchQuery('');
          setActiveIndex(-1);
        }
      }}
      disabled={disabled}
      modal={false}
    >
      {triggerElement ? (
        <Menu.Trigger render={triggerElement} disabled={disabled} />
      ) : (
        <Menu.Trigger disabled={disabled}>{trigger}</Menu.Trigger>
      )}
      <Menu.Portal>
        <Menu.Positioner sideOffset={4} align="center" className="z-[60]">
          <Menu.Popup className="z-[60] bg-white shadow-md shadow-stone-300/50 p-1 rounded-xl border border-stone-200 w-60 flex flex-col gap-1 select-none mx-1 outline-none">
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

                  if (event.key === 'Enter') {
                    event.preventDefault();
                    event.stopPropagation();
                    selectActiveItem();
                    return;
                  }

                  if (event.key !== 'Escape') {
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
