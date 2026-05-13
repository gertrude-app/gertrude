import React from 'react';
import * as DM from '@radix-ui/react-dropdown-menu';

interface Props {
  trigger: React.ReactNode;
  children: React.ReactNode;
  searchable?: boolean;
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

const DropdownMenu: React.FC<Props> = ({ trigger, children, searchable }) => {
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
    <DM.Root
      open={open}
      onOpenChange={(nextOpen) => {
        setOpen(nextOpen);

        if (!nextOpen) {
          setSearchQuery('');
          setActiveIndex(-1);
        }
      }}
    >
      <DM.Trigger asChild>{trigger}</DM.Trigger>
      <DM.Portal>
        <DM.Content
          align="center"
          sideOffset={4}
          className="bg-white shadow-md shadow-stone-300/50 p-1 rounded-xl border border-stone-200 w-60 flex flex-col gap-1"
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
        </DM.Content>
      </DM.Portal>
    </DM.Root>
  );
};

export default DropdownMenu;
