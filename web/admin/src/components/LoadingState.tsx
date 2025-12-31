import React from 'react';
import { LoadingSpinner } from './Icons';

interface LoadingStateProps {
  context: string;
  gradient?: `violet` | `blue` | `green`;
}

const gradients: Record<string, string> = {
  violet: `bg-gradient-to-br from-brand-violet to-brand-fuchsia shadow-brand-violet/20`,
  blue: `bg-gradient-to-br from-sky-400 to-blue-500 shadow-sky-500/20`,
  green: `bg-gradient-to-br from-emerald-400 to-green-500 shadow-emerald-500/20`,
};

const LoadingState: React.FC<LoadingStateProps> = ({ context, gradient = `violet` }) => (
  <div className="flex flex-col items-center justify-center py-24">
    <div
      className={`w-12 h-12 rounded-xl flex items-center justify-center mb-4 shadow-lg ${gradients[gradient]}`}
    >
      <LoadingSpinner className="w-6 h-6 text-white" />
    </div>
    <p className="text-slate-500 font-medium">Loading {context}...</p>
  </div>
);

export default LoadingState;
