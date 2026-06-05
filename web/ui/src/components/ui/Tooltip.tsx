import { Tooltip as BaseTooltip } from '@base-ui/react/tooltip';
import cx from 'clsx';
import React from 'react';
import { useOverlayPortalContainer } from './OverlayPortalContext';

type TooltipRootProps = React.ComponentProps<typeof BaseTooltip.Root>;
type TooltipTriggerProps = React.ComponentProps<typeof BaseTooltip.Trigger>;
type TooltipPositionerProps = React.ComponentProps<typeof BaseTooltip.Positioner>;
type TooltipProviderBaseProps = React.ComponentProps<typeof BaseTooltip.Provider>;

export interface TooltipProviderProps {
  children: React.ReactNode;
  delay?: TooltipProviderBaseProps[`delay`];
  closeDelay?: TooltipProviderBaseProps[`closeDelay`];
  timeout?: TooltipProviderBaseProps[`timeout`];
}

export interface TooltipProps {
  children: React.ReactElement;
  content: React.ReactNode;
  side?: TooltipPositionerProps[`side`];
  align?: TooltipPositionerProps[`align`];
  sideOffset?: TooltipPositionerProps[`sideOffset`];
  alignOffset?: TooltipPositionerProps[`alignOffset`];
  delay?: TooltipTriggerProps[`delay`];
  closeDelay?: TooltipTriggerProps[`closeDelay`];
  disabled?: TooltipRootProps[`disabled`];
  open?: TooltipRootProps[`open`];
  defaultOpen?: TooltipRootProps[`defaultOpen`];
  onOpenChange?: TooltipRootProps[`onOpenChange`];
  showArrow?: boolean;
  positionerClassName?: string;
  contentClassName?: string;
}

const TooltipProviderContext = React.createContext(false);

const arrowClasses = `relative block h-1.5 w-3 overflow-clip data-[side=bottom]:top-[-6px] data-[side=left]:right-[-9px] data-[side=left]:rotate-90 data-[side=right]:left-[-9px] data-[side=right]:-rotate-90 data-[side=top]:bottom-[-6px] data-[side=top]:rotate-180 before:absolute before:bottom-0 before:left-1/2 before:h-[calc(6px*sqrt(2))] before:w-[calc(6px*sqrt(2))] before:-translate-x-1/2 before:translate-y-1/2 before:rotate-45 before:border before:border-stone-950 before:bg-stone-950 before:content-['']`;

export const TooltipProvider: React.FC<TooltipProviderProps> = ({
  children,
  delay = 450,
  closeDelay = 80,
  timeout,
}) => (
  <TooltipProviderContext.Provider value>
    <BaseTooltip.Provider delay={delay} closeDelay={closeDelay} timeout={timeout}>
      {children}
    </BaseTooltip.Provider>
  </TooltipProviderContext.Provider>
);

const TooltipRoot: React.FC<TooltipProps> = ({
  children,
  content,
  side = `top`,
  align = `center`,
  sideOffset = 8,
  alignOffset,
  delay,
  closeDelay,
  disabled,
  open,
  defaultOpen,
  onOpenChange,
  showArrow = true,
  positionerClassName,
  contentClassName,
}) => {
  const overlayPortalContainer = useOverlayPortalContainer();

  return (
    <BaseTooltip.Root
      open={open}
      defaultOpen={defaultOpen}
      onOpenChange={onOpenChange}
      disabled={disabled}
    >
      <BaseTooltip.Trigger
        render={children}
        delay={delay}
        closeDelay={closeDelay}
        disabled={disabled}
      />
      <BaseTooltip.Portal container={overlayPortalContainer ?? undefined}>
        <BaseTooltip.Positioner
          side={side}
          align={align}
          sideOffset={sideOffset}
          alignOffset={alignOffset}
          className={cx(
            `z-[70] max-w-[min(var(--available-width),14rem)]`,
            positionerClassName,
          )}
        >
          <BaseTooltip.Popup
            className={cx(
              `relative origin-[var(--transform-origin)] rounded-lg border border-stone-950 bg-stone-950 px-2 py-1 text-xs font-medium leading-4 text-white shadow-lg shadow-stone-950/20 transition-[opacity,transform] duration-100 ease-out data-ending-style:opacity-0 data-instant:transition-none data-starting-style:opacity-0 data-starting-style:[transform:scale(0.98)]`,
              contentClassName,
            )}
          >
            {showArrow && <BaseTooltip.Arrow className={arrowClasses} />}
            {content}
          </BaseTooltip.Popup>
        </BaseTooltip.Positioner>
      </BaseTooltip.Portal>
    </BaseTooltip.Root>
  );
};

const Tooltip: React.FC<TooltipProps> = (props) => {
  const hasProvider = React.useContext(TooltipProviderContext);
  const tooltip = <TooltipRoot {...props} />;

  return hasProvider ? tooltip : <TooltipProvider>{tooltip}</TooltipProvider>;
};

export default Tooltip;
