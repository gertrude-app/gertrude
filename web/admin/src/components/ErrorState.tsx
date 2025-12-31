import React from 'react';
import { AlertCircleIcon } from './Icons';

interface ErrorStateProps {
  context: string;
  error: string;
}

const ErrorState: React.FC<ErrorStateProps> = ({ context, error }) => (
  <div className="bg-red-50 border border-red-100 rounded-2xl p-6">
    <div className="flex items-start gap-4">
      <div className="w-10 h-10 rounded-xl bg-gradient-to-br from-red-400 to-red-500 flex items-center justify-center flex-shrink-0">
        <AlertCircleIcon className="w-5 h-5 text-white" />
      </div>
      <div>
        <h3 className="font-display font-semibold text-red-900">
          Failed to load {context}
        </h3>
        <p className="mt-1 text-red-700">{error}</p>
      </div>
    </div>
  </div>
);

export default ErrorState;
