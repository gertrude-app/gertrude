import { CheckIcon } from 'lucide-react';
import React from 'react';
import Badge from '#/components/ui/Badge';

type BadgeColor =
  `neutral` | `violet` | `red` | `green` | `blue` | `yellow` | `beta` | `canary`;

const colors: BadgeColor[] = [
  `neutral`,
  `violet`,
  `red`,
  `green`,
  `blue`,
  `yellow`,
  `beta`,
  `canary`,
];

const labels: Record<BadgeColor, string> = {
  neutral: `Neutral`,
  violet: `Setup`,
  red: `Blocked`,
  green: `Allowed`,
  blue: `Managed`,
  yellow: `Pending`,
  beta: `Beta`,
  canary: `Canary`,
};

const ColorVariantsExample: React.FC = () => (
  <div className="flex h-full items-center justify-center p-8">
    <div className="grid gap-4">
      {colors.map((color) => (
        <div key={color} className="grid items-center gap-3 sm:grid-cols-[5rem_1fr]">
          <div className="font-mono text-xs text-stone-500">{color}</div>
          <div className="flex flex-wrap items-center gap-3">
            <Badge color={color}>{labels[color]}</Badge>
            <Badge color={color} icon={CheckIcon}>
              {labels[color]}
            </Badge>
          </div>
        </div>
      ))}
    </div>
  </div>
);

export default ColorVariantsExample;
