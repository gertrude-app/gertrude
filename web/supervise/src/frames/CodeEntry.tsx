import { Button, CodeInput, Logo } from '@shared/components';
import React from 'react';
import type { CodeEntryProps } from '../types';
import FrameBackground from '../FrameBackground';

const CodeEntry: React.FC<CodeEntryProps> = ({
  code,
  onCodeChange,
  onSubmit,
  loading,
  error,
}) => {
  const codeValid = code.length === 6;

  return (
    <FrameBackground>
      <div className="flex flex-col items-center justify-center max-w-md">
        <Logo size={120} textSize="text-6xl" className="mb-3" />
        <span className="text-base font-semibold uppercase tracking-wider bg-gradient-to-r from-violet-500 to-fuchsia-500 bg-clip-text [-webkit-background-clip:text] text-transparent mb-12">
          Supervision Helper
        </span>

        <p className={`text-base mb-4 ${error ? `text-red-600` : `text-slate-500`}`}>
          {error ?? `Enter the 6-digit code from the Gertrude app:`}
        </p>

        <CodeInput
          value={code}
          onChange={onCodeChange}
          onSubmit={onSubmit}
          disabled={loading}
          className="w-80 mb-8 text-2xl"
        />

        <Button
          type="button"
          onClick={onSubmit}
          disabled={!codeValid || loading}
          color="gradient"
          size="large"
        >
          {loading ? `Verifying...` : <>Continue &rarr;</>}
        </Button>
      </div>
    </FrameBackground>
  );
};

export default CodeEntry;
