import React from 'react';
import Tooltip, { TooltipProvider } from '#/components/ui/Tooltip';

type TooltipSide = `top` | `right` | `bottom` | `left`;

const PlacementExample: React.FC = () => (
  <div className="flex h-full items-center justify-center p-8">
    <TooltipProvider delay={250}>
      <div className="grid grid-cols-3 grid-rows-3 items-center justify-items-center gap-4">
        <div />
        <PlacementButton side="top" />
        <div />
        <PlacementButton side="left" />
        <div className="rounded-2xl border border-stone-200 bg-stone-50 px-5 py-4 text-center text-sm text-stone-500">
          Sides
        </div>
        <PlacementButton side="right" />
        <div />
        <PlacementButton side="bottom" />
        <div />
      </div>
    </TooltipProvider>
  </div>
);

interface PlacementButtonProps {
  side: TooltipSide;
}

const PlacementButton: React.FC<PlacementButtonProps> = ({ side }) => (
  <Tooltip content={`Tooltip on the ${side}`} side={side}>
    <button
      type="button"
      aria-label={`Show ${side} tooltip`}
      className="rounded-full border border-stone-200 bg-white px-4 py-2 text-sm font-medium capitalize text-stone-800 shadow-sm shadow-stone-300/40 transition hover:border-stone-300 hover:bg-stone-50 focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-violet-400"
    >
      {side}
    </button>
  </Tooltip>
);

export default PlacementExample;
