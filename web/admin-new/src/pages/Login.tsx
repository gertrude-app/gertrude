import React, { useState } from 'react';
import client from '../api/client';

interface GertrudeLogoProps {
  className?: string;
  variant?: `gradient` | `light` | `white`;
}

const GertrudeLogo: React.FC<GertrudeLogoProps> = ({
  className = ``,
  variant = `gradient`,
}) => {
  const gradientId = `logoGradient-${Math.random().toString(36).slice(2, 9)}`;
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

interface IconProps {
  className?: string;
}

const MailIcon: React.FC<IconProps> = ({ className = `` }) => (
  <svg
    xmlns="http://www.w3.org/2000/svg"
    viewBox="0 0 24 24"
    fill="none"
    stroke="currentColor"
    strokeWidth="1.5"
    strokeLinecap="round"
    strokeLinejoin="round"
    className={className}
  >
    <rect width="20" height="16" x="2" y="4" rx="2" />
    <path d="m22 7-8.97 5.7a1.94 1.94 0 0 1-2.06 0L2 7" />
  </svg>
);

const ArrowRightIcon: React.FC<IconProps> = ({ className = `` }) => (
  <svg
    xmlns="http://www.w3.org/2000/svg"
    viewBox="0 0 24 24"
    fill="none"
    stroke="currentColor"
    strokeWidth="2"
    strokeLinecap="round"
    strokeLinejoin="round"
    className={className}
  >
    <path d="M5 12h14" />
    <path d="m12 5 7 7-7 7" />
  </svg>
);

const CheckCircleIcon: React.FC<IconProps> = ({ className = `` }) => (
  <svg
    xmlns="http://www.w3.org/2000/svg"
    viewBox="0 0 24 24"
    fill="none"
    stroke="currentColor"
    strokeWidth="1.5"
    strokeLinecap="round"
    strokeLinejoin="round"
    className={className}
  >
    <circle cx="12" cy="12" r="10" />
    <path d="m9 12 2 2 4-4" />
  </svg>
);

const Login: React.FC = () => {
  const [email, setEmail] = useState(``);
  const [status, setStatus] = useState<`idle` | `loading` | `sent` | `error`>(`idle`);
  const [errorMsg, setErrorMsg] = useState(``);

  const handleSubmit = async (e: React.FormEvent): Promise<void> => {
    e.preventDefault();
    setStatus(`loading`);
    setErrorMsg(``);

    const result = await client.requestMagicLink({ email });

    if (result.isSuccess) {
      setStatus(`sent`);
    } else {
      setStatus(`error`);
      setErrorMsg(result.error?.debugMessage ?? `Failed to send magic link`);
    }
  };

  if (status === `sent`) {
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

            <div className="bg-white rounded-2xl border border-slate-200/80 shadow-sm shadow-slate-200/50 p-8">
              <div className="w-14 h-14 rounded-xl bg-gradient-to-br from-emerald-400 to-emerald-500 flex items-center justify-center mb-6 shadow-lg shadow-emerald-500/20">
                <CheckCircleIcon className="w-7 h-7 text-white" />
              </div>

              <h1 className="text-2xl font-display font-semibold text-slate-900 tracking-tight">
                Check your inbox
              </h1>
              <p className="mt-3 text-slate-500 leading-relaxed">
                We sent a magic link to{` `}
                <span className="font-medium text-slate-700">{email}</span>. Click the
                link in the email to sign in.
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
  }

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

          <div className="bg-white rounded-2xl border border-slate-200/80 shadow-sm shadow-slate-200/50 p-8">
            <div className="w-14 h-14 rounded-xl bg-gradient-to-br from-brand-violet to-brand-fuchsia flex items-center justify-center mb-6 shadow-lg shadow-brand-violet/20">
              <MailIcon className="w-7 h-7 text-white" />
            </div>

            <h1 className="text-2xl font-display font-semibold text-slate-900 tracking-tight">
              Sign in to Admin
            </h1>
            <p className="mt-2 text-slate-500">
              Enter your email to receive a magic link
            </p>

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
                      <svg
                        className="w-5 h-5 animate-spin"
                        viewBox="0 0 24 24"
                        fill="none"
                      >
                        <circle
                          className="opacity-25"
                          cx="12"
                          cy="12"
                          r="10"
                          stroke="currentColor"
                          strokeWidth="4"
                        />
                        <path
                          className="opacity-75"
                          fill="currentColor"
                          d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"
                        />
                      </svg>
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

          <p className="mt-8 text-center text-sm text-slate-400">
            Authorized personnel only
          </p>
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

export default Login;
