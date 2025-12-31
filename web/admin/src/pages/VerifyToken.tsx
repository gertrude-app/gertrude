import React, { useEffect, useState } from 'react';
import { useNavigate, useParams } from 'react-router-dom';
import client from '../api/client';
import { ArrowLeftIcon, LoadingSpinner, XCircleIcon } from '../components/Icons';
import SplitLayout from '../components/SplitLayout';

interface VerifyTokenProps {
  onLogin: (token: string) => void;
}

const VerifyToken: React.FC<VerifyTokenProps> = ({ onLogin }) => {
  const { token } = useParams<{ token: string }>();
  const navigate = useNavigate();
  const [status, setStatus] = useState<`verifying` | `error`>(`verifying`);
  const [errorMsg, setErrorMsg] = useState(``);

  useEffect(() => {
    if (!token) {
      setStatus(`error`);
      setErrorMsg(`No token provided`);
      return;
    }

    const verifyToken = async (): Promise<void> => {
      const result = await client.verifyAdminMagicLink({ token });

      if (result.isSuccess && result.value) {
        onLogin(result.value.token);
        navigate(`/`, { replace: true });
      } else {
        setStatus(`error`);
        setErrorMsg(result.error?.debugMessage ?? `Invalid or expired magic link`);
      }
    };

    verifyToken();
  }, [token, onLogin, navigate]);

  return (
    <SplitLayout>
      {status === `verifying` ? (
        <div className="bg-white rounded-2xl border border-slate-200/80 shadow-sm shadow-slate-200/50 p-8">
          <div className="w-14 h-14 rounded-xl bg-gradient-to-br from-brand-violet to-brand-fuchsia flex items-center justify-center mb-6 shadow-lg shadow-brand-violet/20">
            <LoadingSpinner className="w-7 h-7 text-white" />
          </div>

          <h1 className="text-2xl font-display font-semibold text-slate-900 tracking-tight">
            Verifying your link
          </h1>
          <p className="mt-3 text-slate-500 leading-relaxed">
            Please wait while we verify your magic link and sign you in.
          </p>

          <div className="mt-8 flex gap-1">
            {[0, 1, 2].map((i) => (
              <div
                key={i}
                className="h-1 flex-1 bg-slate-100 rounded-full overflow-hidden"
              >
                <div
                  className="h-full bg-gradient-to-r from-brand-violet to-brand-fuchsia rounded-full animate-pulse"
                  style={{
                    animationDelay: `${i * 200}ms`,
                  }}
                />
              </div>
            ))}
          </div>
        </div>
      ) : (
        <div className="bg-white rounded-2xl border border-slate-200/80 shadow-sm shadow-slate-200/50 p-8">
          <div className="w-14 h-14 rounded-xl bg-gradient-to-br from-red-400 to-red-500 flex items-center justify-center mb-6 shadow-lg shadow-red-500/20">
            <XCircleIcon className="w-7 h-7 text-white" />
          </div>

          <h1 className="text-2xl font-display font-semibold text-slate-900 tracking-tight">
            Verification failed
          </h1>
          <p className="mt-3 text-slate-500 leading-relaxed">{errorMsg}</p>

          <button
            onClick={() => navigate(`/`, { replace: true })}
            className="mt-8 w-full relative group bg-gradient-to-r from-brand-violet to-brand-fuchsia text-white font-semibold py-3.5 px-6 rounded-xl transition-all hover:shadow-lg hover:shadow-brand-violet/25 hover:-translate-y-0.5 active:translate-y-0"
          >
            <span className="flex items-center justify-center gap-2">
              <ArrowLeftIcon className="w-5 h-5" />
              <span>Back to login</span>
            </span>
          </button>
        </div>
      )}
    </SplitLayout>
  );
};

export default VerifyToken;
