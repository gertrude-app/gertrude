import React from 'react';

export type Props = {
  extraBullets?: string[];
  priceSize?: `normal` | `emphasized`;
  className?: string;
};

const CANONICAL_BULLETS = [
  `Covers your whole family with one subscription`,
  `Use on unlimited iPhones and iPads`,
];

const LightPlanTeaser: React.FC<Props> = ({
  extraBullets = [],
  priceSize = `normal`,
  className,
}) => {
  const bullets = [...CANONICAL_BULLETS, ...extraBullets];
  return (
    <div
      className={`rounded-2xl p-[2px] bg-gradient-to-r from-violet-500 to-fuchsia-500 ${className ?? ``}`}
    >
      <div className="rounded-[14px] p-5 bg-white">
        <div className="flex items-baseline justify-between mb-4">
          <h3 className="text-lg font-bold text-slate-800">Light Plan</h3>
          {priceSize === `emphasized` ? (
            <div>
              <span className="text-3xl font-bold text-violet-700">$10</span>
              <span className="text-sm font-medium text-slate-500"> / year</span>
            </div>
          ) : (
            <span className="text-lg font-bold text-violet-700">$10/year</span>
          )}
        </div>
        <ul className="space-y-2">
          {bullets.map((bullet) => (
            <li key={bullet} className="flex items-center gap-2 text-sm text-slate-600">
              <i className="fa-solid fa-check text-violet-500 text-xs" />
              {bullet}
            </li>
          ))}
        </ul>
        <p className="text-xs text-slate-400 mt-3">One annual payment. Cancel anytime.</p>
      </div>
    </div>
  );
};

export default LightPlanTeaser;
