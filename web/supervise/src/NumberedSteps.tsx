import React from 'react';

interface Step {
  title: React.ReactNode;
  subtitle?: React.ReactNode;
}

interface Props {
  steps: Step[];
  variant?: `numbered` | `checkmark`;
}

const NumberedSteps: React.FC<Props> = ({ steps, variant = `numbered` }) => (
  <div className="flex flex-col gap-4">
    {steps.map((step, i) => (
      <div key={i} className="flex items-start gap-4">
        <span
          className={`w-8 h-8 rounded-full text-sm font-bold flex items-center justify-center shrink-0 mt-0.5 ${
            variant === `checkmark`
              ? `bg-emerald-100 text-emerald-600`
              : `bg-violet-100 text-violet-600`
          }`}
        >
          {variant === `checkmark` ? `✓` : i + 1}
        </span>
        <div>
          <span className="text-base font-medium text-slate-700">{step.title}</span>
          {step.subtitle && (
            <p className="text-sm text-slate-500 mt-0.5">{step.subtitle}</p>
          )}
        </div>
      </div>
    ))}
  </div>
);

export default NumberedSteps;
