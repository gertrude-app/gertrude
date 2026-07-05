import { Button, Tooltip } from '@gertrude/ui';
import cx from 'clsx';
import { FlagIcon, GripVerticalIcon, TrashIcon } from 'lucide-react';
import React from 'react';

interface Props {
  id: string;
  screenshotUrl: string;
  width: number;
  height: number;
  date: Date;
  flagged: boolean;
  onToggleFlag?: (id: string) => void;
  onDelete?: (id: string) => void;
}

type ControlsCorner = `topLeft` | `topRight` | `bottomLeft` | `bottomRight`;

const cornerClasses: Record<ControlsCorner, string> = {
  topLeft: `justify-start items-start`,
  topRight: `justify-end items-start`,
  bottomLeft: `justify-start items-end`,
  bottomRight: `justify-end items-end`,
};

type DragPosition = { x: number; y: number };

function clamp(value: number, min: number, max: number): number {
  return Math.min(Math.max(value, min), Math.max(min, max));
}

const ScreenshotActivityItem: React.FC<Props> = ({
  id,
  screenshotUrl,
  width,
  height,
  flagged,
  onToggleFlag,
  onDelete,
}) => {
  const containerRef = React.useRef<HTMLDivElement>(null);
  const overlayRef = React.useRef<HTMLDivElement>(null);
  const controlsRef = React.useRef<HTMLDivElement>(null);
  const draggingRef = React.useRef(false);
  const dragOffsetRef = React.useRef<DragPosition>({ x: 0, y: 0 });
  const [controlsCorner, setControlsCorner] =
    React.useState<ControlsCorner>(`bottomRight`);
  const [dragging, setDragging] = React.useState(false);
  const [dragPosition, setDragPosition] = React.useState<DragPosition | null>(null);
  const [dragTargetCorner, setDragTargetCorner] = React.useState<ControlsCorner | null>(
    null,
  );

  const getControlsCorner = (clientX: number, clientY: number): ControlsCorner | null => {
    const bounds = containerRef.current?.getBoundingClientRect();

    if (!bounds) {
      return null;
    }

    const isTop = clientY < bounds.top + bounds.height / 2;
    const isLeft = clientX < bounds.left + bounds.width / 2;

    return isTop
      ? isLeft
        ? `topLeft`
        : `topRight`
      : isLeft
        ? `bottomLeft`
        : `bottomRight`;
  };

  const updateControlsCorner = (clientX: number, clientY: number): void => {
    const corner = getControlsCorner(clientX, clientY);

    if (corner) {
      setControlsCorner(corner);
    }
  };

  const updateDragPosition = (clientX: number, clientY: number): void => {
    const bounds = overlayRef.current?.getBoundingClientRect();
    const controlsBounds = controlsRef.current?.getBoundingClientRect();

    if (!bounds || !controlsBounds) {
      return;
    }

    const corner = getControlsCorner(clientX, clientY);

    if (corner) {
      setDragTargetCorner(corner);
    }

    const margin = 8;

    setDragPosition({
      x: clamp(
        clientX - bounds.left - dragOffsetRef.current.x,
        margin,
        bounds.width - controlsBounds.width - margin,
      ),
      y: clamp(
        clientY - bounds.top - dragOffsetRef.current.y,
        margin,
        bounds.height - controlsBounds.height - margin,
      ),
    });
  };

  const handleGripPointerDown = (event: React.PointerEvent<HTMLButtonElement>): void => {
    const controlsBounds = controlsRef.current?.getBoundingClientRect();

    event.preventDefault();
    event.stopPropagation();
    event.currentTarget.setPointerCapture(event.pointerId);

    if (controlsBounds) {
      dragOffsetRef.current = {
        x: event.clientX - controlsBounds.left,
        y: event.clientY - controlsBounds.top,
      };
    }

    draggingRef.current = true;
    setDragging(true);
    updateDragPosition(event.clientX, event.clientY);
  };

  const handleGripPointerMove = (event: React.PointerEvent<HTMLButtonElement>): void => {
    if (!draggingRef.current) {
      return;
    }

    updateDragPosition(event.clientX, event.clientY);
  };

  const handleGripPointerEnd = (event: React.PointerEvent<HTMLButtonElement>): void => {
    if (draggingRef.current) {
      updateControlsCorner(event.clientX, event.clientY);
    }

    draggingRef.current = false;
    setDragging(false);
    setDragPosition(null);
    setDragTargetCorner(null);

    if (event.currentTarget.hasPointerCapture(event.pointerId)) {
      event.currentTarget.releasePointerCapture(event.pointerId);
    }
  };

  return (
    <div ref={containerRef} className="relative">
      {/* close dark shadow */}
      <img
        src={screenshotUrl}
        width={width}
        height={height}
        alt="screenshot"
        className="rounded-xl absolute inset-0 blur-xs translate-y-0.5 opacity-60"
      />

      {/* big light shadow */}
      <img
        src={screenshotUrl}
        width={width}
        height={height}
        alt="screenshot"
        className="rounded-xl absolute inset-0 blur-md translate-y-1 opacity-70"
      />

      {/* actual screenshot */}
      <img
        src={screenshotUrl}
        width={width}
        height={height}
        alt="screenshot"
        className="rounded-xl relative border border-black/40"
      />

      {(onToggleFlag || onDelete) && (
        <div
          ref={overlayRef}
          className={`absolute inset-0.25 border border-white/50 rounded-[11.5px] flex ${cornerClasses[controlsCorner]} p-2 pointer-events-none overflow-hidden`}
        >
          {/* top left drop zone */}
          <>
            <div
              className={cx(
                `absolute w-1/2 h-1/2 -left-1/4 -top-1/4 rounded-[100%] bg-violet-400 blur-3xl transition-opacity duration-300`,
                dragging && dragTargetCorner === `topLeft` ? `opacity-30` : `opacity-0`,
              )}
            />
            <div
              className={cx(
                `w-[216px] @lg/main:w-[224px] h-[46px] @lg/main:h-[54px] bg-white/60 border-2 border-white absolute top-2 left-2 rounded-xl @lg/main:rounded-2xl transition-opacity duration-300`,
                dragging && dragTargetCorner === `topLeft` ? `opacity-100` : `opacity-0`,
              )}
            />
          </>

          {/* top right drop zone */}
          <>
            <div
              className={cx(
                `absolute w-1/2 h-1/2 -right-1/4 -top-1/4 rounded-[100%] bg-violet-400 blur-3xl transition-opacity duration-300`,
                dragging && dragTargetCorner === `topRight` ? `opacity-30` : `opacity-0`,
              )}
            />
            <div
              className={cx(
                `w-[216px] @lg/main:w-[224px] h-[46px] @lg/main:h-[54px] bg-white/60 border-2 border-white absolute top-2 right-2 rounded-xl @lg/main:rounded-2xl transition-opacity duration-300`,
                dragging && dragTargetCorner === `topRight` ? `opacity-100` : `opacity-0`,
              )}
            />
          </>

          {/* bottom right drop zone */}
          <>
            <div
              className={cx(
                `absolute w-1/2 h-1/2 -right-1/4 -bottom-1/4 rounded-[100%] bg-violet-400 blur-3xl transition-opacity duration-300`,
                dragging && dragTargetCorner === `bottomRight`
                  ? `opacity-30`
                  : `opacity-0`,
              )}
            />
            <div
              className={cx(
                `w-[216px] @lg/main:w-[224px] h-[46px] @lg/main:h-[54px] bg-white/60 border-2 border-white absolute bottom-2 right-2 rounded-xl @lg/main:rounded-2xl transition-opacity duration-300`,
                dragging && dragTargetCorner === `bottomRight`
                  ? `opacity-100`
                  : `opacity-0`,
              )}
            />
          </>

          {/* bottom left drop zone */}
          <>
            <div
              className={cx(
                `absolute w-1/2 h-1/2 -left-1/4 -bottom-1/4 rounded-[100%] bg-violet-400 blur-3xl transition-opacity duration-300`,
                dragging && dragTargetCorner === `bottomLeft`
                  ? `opacity-30`
                  : `opacity-0`,
              )}
            />
            <div
              className={cx(
                `w-[216px] @lg/main:w-[224px] h-[46px] @lg/main:h-[54px] bg-white/60 border-2 border-white absolute bottom-2 left-2 rounded-xl @lg/main:rounded-2xl transition-opacity duration-300`,
                dragging && dragTargetCorner === `bottomLeft`
                  ? `opacity-100`
                  : `opacity-0`,
              )}
            />
          </>

          {/* controls */}
          <div
            ref={controlsRef}
            className={cx(
              `flex items-center gap-2 p-1 @lg/main:p-2 bg-white/70 border border-white/50 ring ring-black/10 backdrop-blur-md rounded-xl @lg/main:rounded-2xl pointer-events-auto select-none shadow-md shadow-black/5`,
              dragPosition ? `absolute z-10` : `relative`,
            )}
            style={
              dragPosition ? { left: dragPosition.x, top: dragPosition.y } : undefined
            }
          >
            <button
              type="button"
              aria-label="Move screenshot controls"
              className={`rounded-lg p-1 text-black/50 hover:text-black/70 focus-visible:outline focus-visible:outline-offset-2 focus-visible:outline-black/40 touch-none ${
                dragging ? `cursor-grabbing` : `cursor-grab`
              }`}
              onPointerDown={handleGripPointerDown}
              onPointerMove={handleGripPointerMove}
              onPointerUp={handleGripPointerEnd}
              onPointerCancel={handleGripPointerEnd}
            >
              <GripVerticalIcon className="h-4 w-4" />
            </button>
            <Tooltip
              content={
                flagged
                  ? `Flagged items won't be deleted for 60 days`
                  : `Flag to prevent deletion for 60 days`
              }
            >
              <Button
                type="button"
                onClick={() => onToggleFlag?.(id)}
                icon={FlagIcon}
                fillIcon={flagged}
                variant={flagged ? `selected` : `ghost`}
              >
                {flagged ? `Flagged` : `Flag`}
              </Button>
            </Tooltip>
            <Button type="button" onClick={() => onDelete?.(id)} icon={TrashIcon}>
              Delete
            </Button>
          </div>
        </div>
      )}
    </div>
  );
};

export default ScreenshotActivityItem;
