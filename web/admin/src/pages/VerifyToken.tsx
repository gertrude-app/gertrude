import React, { useEffect, useState } from 'react';
import { useNavigate, useParams } from 'react-router-dom';
import client from '../api/client';

interface GertrudeLogoProps {
  className?: string;
  variant?: `gradient` | `light` | `white`;
}

const GertrudeLogo: React.FC<GertrudeLogoProps> = ({
  className = ``,
  variant = `gradient`,
}) => {
  const gradientId = `logoGradientVerify-${Math.random().toString(36).slice(2, 9)}`;
  const fills: Record<string, { start: string; end: string } | string> = {
    gradient: { start: `#8B5CF6`, end: `#D846EF` },
    light: { start: `#A78BFA`, end: `#E879F9` },
    white: `white`,
  };
  const fill = fills[variant];
  const isGradient = typeof fill === `object`;

  return (
    <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1250 1240" className={className}>
      {isGradient && (
        <defs>
          <linearGradient id={gradientId} x1="0" x2="0" y1="0" y2="1">
            <stop stopColor={fill.start} />
            <stop offset="1" stopColor={fill.end} />
          </linearGradient>
        </defs>
      )}
      <path
        d="M 595.177 170.634 C 561.903 175.767, 530.633 189.195, 504.039 209.770 C 482.421 226.495, 216.195 494.797, 206.126 510.005 C 161.875 576.845, 163.739 667.193, 210.616 727.631 C 222.488 742.937, 460.408 982.095, 502.761 1021.295 C 568.157 1081.824, 679.283 1082.653, 747.825 1023.124 C 779.646 995.487, 1032.850 739.640, 1041.878 726 C 1086.096 659.201, 1084.243 573.409, 1037.194 509 C 1031.604 501.347, 764.863 233.177, 746.040 216.285 C 706.625 180.914, 646.493 162.719, 595.177 170.634 M 631.500 349.485 C 611.720 353.858, 609.836 354.943, 513.500 417.474 C 398.233 492.291, 387.820 499.457, 378.809 510.167 C 350.091 544.300, 344.115 595.501, 364.708 630.989 C 383.738 663.785, 499.067 839.766, 507.431 848.772 C 547.214 891.607, 601.147 894.239, 660.500 856.242 C 689.279 837.819, 805.262 762.488, 828.080 747.400 C 882.786 711.226, 900.744 667.270, 882.888 613.239 C 878.898 601.165, 829.728 523.097, 751.101 404 C 722 359.921, 677.025 339.421, 631.500 349.485"
        stroke="none"
        fillRule="evenodd"
        fill={isGradient ? `url(#${gradientId})` : fill}
      />
    </svg>
  );
};

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
    <div className="min-h-screen flex">
      <div className="flex-1 flex items-center justify-center p-8 bg-slate-50">
        <div className="w-full max-w-md animate-fade-in">
          <div className="lg:hidden flex items-center gap-3 mb-12">
            <GertrudeLogo className="w-10 h-10" />
            <span className="font-display font-semibold text-xl text-slate-800">
              Gertrude
            </span>
          </div>

          {status === `verifying` ? (
            <div className="bg-white rounded-2xl border border-slate-200/80 shadow-sm shadow-slate-200/50 p-8">
              <div className="w-14 h-14 rounded-xl bg-gradient-to-br from-brand-violet to-brand-fuchsia flex items-center justify-center mb-6 shadow-lg shadow-brand-violet/20">
                <svg
                  className="w-7 h-7 text-white animate-spin"
                  viewBox="0 0 24 24"
                  fill="none"
                >
                  <circle
                    className="opacity-25"
                    cx="12"
                    cy="12"
                    r="10"
                    stroke="currentColor"
                    strokeWidth="3"
                  />
                  <path
                    className="opacity-75"
                    fill="currentColor"
                    d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"
                  />
                </svg>
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
                <svg
                  className="w-7 h-7 text-white"
                  viewBox="0 0 24 24"
                  fill="none"
                  stroke="currentColor"
                  strokeWidth="1.5"
                  strokeLinecap="round"
                  strokeLinejoin="round"
                >
                  <circle cx="12" cy="12" r="10" />
                  <path d="m15 9-6 6M9 9l6 6" />
                </svg>
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
                  <svg
                    className="w-5 h-5"
                    viewBox="0 0 24 24"
                    fill="none"
                    stroke="currentColor"
                    strokeWidth="2"
                    strokeLinecap="round"
                    strokeLinejoin="round"
                  >
                    <path d="m12 19-7-7 7-7" />
                    <path d="M19 12H5" />
                  </svg>
                  <span>Back to login</span>
                </span>
              </button>
            </div>
          )}
        </div>
      </div>

      <div className="hidden lg:flex lg:w-1/2 bg-gradient-to-br from-slate-900 via-slate-800 to-slate-900 relative overflow-hidden">
        <div className="absolute inset-0 opacity-30">
          <div className="absolute top-1/4 -left-20 w-96 h-96 bg-brand-violet/20 rounded-full blur-3xl" />
          <div className="absolute bottom-1/4 -right-20 w-96 h-96 bg-brand-fuchsia/20 rounded-full blur-3xl" />
        </div>
        <div
          className="absolute inset-0 opacity-[0.015]"
          style={{
            backgroundImage: `url("data:image/svg+xml,%3Csvg viewBox='0 0 400 400' xmlns='http://www.w3.org/2000/svg'%3E%3Cfilter id='noiseFilter'%3E%3CfeTurbulence type='fractalNoise' baseFrequency='0.9' numOctaves='4' stitchTiles='stitch'/%3E%3C/filter%3E%3Crect width='100%25' height='100%25' filter='url(%23noiseFilter)'/%3E%3C/svg%3E")`,
          }}
        />
        <div className="relative z-10 flex flex-col justify-center items-center w-full p-12">
          <GertrudeLogo className="w-32 h-32 animate-float" variant="light" />
          <h2 className="mt-2 text-3xl font-display font-semibold text-white/90 tracking-tight">
            Gertrude
          </h2>
          <p className="mt-2 text-white/40 font-medium tracking-widest uppercase text-xs">
            Admin Portal
          </p>
        </div>
      </div>
    </div>
  );
};

export default VerifyToken;
