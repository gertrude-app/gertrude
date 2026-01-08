import React, { useState } from 'react';
import client from '../api/client';
import {
  ArrowRightIcon,
  CheckCircleIcon,
  LoadingSpinner,
  MailIcon,
} from '../components/Icons';
import SplitLayout from '../components/SplitLayout';

const Login: React.FC = () => {
  const [email, setEmail] = useState(``);
  const [status, setStatus] = useState<`idle` | `loading` | `sent` | `error`>(`idle`);
  const [errorMsg, setErrorMsg] = useState(``);

  const handleSubmit = async (e: React.FormEvent): Promise<void> => {
    e.preventDefault();
    setStatus(`loading`);
    setErrorMsg(``);

    const origin = window.location.origin;
    const isProduction = origin === `https://admin.gertrude.app`;
    const overrideAdminUrl = isProduction ? undefined : origin;

    const result = await client.requestAdminMagicLink({ email, overrideAdminUrl });

    if (result.isSuccess) {
      setStatus(`sent`);
    } else {
      setStatus(`error`);
      setErrorMsg(result.error?.debugMessage ?? `Failed to send magic link`);
    }
  };

  if (status === `sent`) {
    return (
      <SplitLayout>
        <div className="bg-white rounded-2xl border border-slate-200/80 shadow-sm shadow-slate-200/50 p-8">
          <div className="w-14 h-14 rounded-xl bg-gradient-to-br from-emerald-400 to-emerald-500 flex items-center justify-center mb-6 shadow-lg shadow-emerald-500/20">
            <CheckCircleIcon className="w-7 h-7 text-white" />
          </div>

          <h1 className="text-2xl font-display font-semibold text-slate-900 tracking-tight">
            Check your inbox
          </h1>
          <p className="mt-3 text-slate-500 leading-relaxed">
            We sent a magic link to{` `}
            <span className="font-medium text-slate-700">{email}</span>. Click the link in
            the email to sign in.
          </p>

          <div className="mt-8 pt-6 border-t border-slate-100">
            <p className="text-sm text-slate-400">
              Didn't receive it?{` `}
              <button
                onClick={() => {
                  setStatus(`idle`);
                  setEmail(``);
                }}
                className="text-brand-violet hover:text-brand-fuchsia font-medium transition-colors"
              >
                Try again
              </button>
            </p>
          </div>
        </div>
      </SplitLayout>
    );
  }

  return (
    <SplitLayout>
      <div className="bg-white rounded-2xl border border-slate-200/80 shadow-sm shadow-slate-200/50 p-8">
        <div className="w-14 h-14 rounded-xl bg-gradient-to-br from-brand-violet to-brand-fuchsia flex items-center justify-center mb-6 shadow-lg shadow-brand-violet/20">
          <MailIcon className="w-7 h-7 text-white" />
        </div>

        <h1 className="text-2xl font-display font-semibold text-slate-900 tracking-tight">
          Sign in to Admin
        </h1>
        <p className="mt-2 text-slate-500">Enter your email to receive a magic link</p>

        <form onSubmit={handleSubmit} className="mt-8 space-y-5">
          <div>
            <label
              htmlFor="email"
              className="block text-sm font-medium text-slate-700 mb-2"
            >
              Email address
            </label>
            <input
              type="email"
              id="email"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              required
              autoFocus
              className="w-full px-4 py-3 bg-slate-50 border border-slate-200 rounded-xl text-slate-900 placeholder:text-slate-400 focus:outline-none focus:ring-2 focus:ring-brand-violet/20 focus:border-brand-violet transition-all"
              placeholder="you@company.com"
            />
          </div>

          {status === `error` && (
            <div className="flex items-start gap-3 text-red-600 text-sm bg-red-50 border border-red-100 p-4 rounded-xl">
              <svg
                className="w-5 h-5 flex-shrink-0 mt-0.5"
                viewBox="0 0 24 24"
                fill="none"
                stroke="currentColor"
                strokeWidth="1.5"
              >
                <circle cx="12" cy="12" r="10" />
                <path d="M12 8v4M12 16h.01" />
              </svg>
              <span>{errorMsg}</span>
            </div>
          )}

          <button
            type="submit"
            disabled={status === `loading`}
            className="w-full relative group bg-gradient-to-r from-brand-violet to-brand-fuchsia text-white font-semibold py-3.5 px-6 rounded-xl transition-all disabled:opacity-60 disabled:cursor-not-allowed hover:shadow-lg hover:shadow-brand-violet/25 hover:-translate-y-0.5 active:translate-y-0"
          >
            <span className="flex items-center justify-center gap-2">
              {status === `loading` ? (
                <>
                  <LoadingSpinner className="w-5 h-5" />
                  <span>Sending...</span>
                </>
              ) : (
                <>
                  <span>Send magic link</span>
                  <ArrowRightIcon className="w-5 h-5 group-hover:translate-x-0.5 transition-transform" />
                </>
              )}
            </span>
          </button>
        </form>
      </div>

      <p className="mt-8 text-center text-sm text-slate-400">Authorized personnel only</p>
    </SplitLayout>
  );
};

export default Login;
