import { FullscreenGradientBg } from '@dash/components';
import cx from 'classnames';
import React, { useState } from 'react';
import { Navigate, useNavigate, useSearchParams } from 'react-router-dom';
import Current from '../../environment';
import { useAuth } from '../../hooks';

const REFERRAL_EVENT_ID = `e7b3a1c9`;

const OPTIONS = [
  { token: `friend_family`, icon: `fa-user-group`, label: `A friend or family member` },
  {
    token: `community_group`,
    icon: `fa-people-group`,
    label: `Church, homeschool, or community group`,
  },
  {
    token: `search_engine`,
    icon: `fa-magnifying-glass`,
    label: `Search engine (Google, etc.)`,
  },
  { token: `app_store`, icon: `fa-app-store`, brand: true, label: `App Store` },
  {
    token: `social_media`,
    icon: `fa-share-nodes`,
    label: `Social media (Reddit, YouTube, Facebook, etc.)`,
  },
  { token: `article_news`, icon: `fa-newspaper`, label: `A blog, article, or the news` },
] as const;

const ReferralSurvey: React.FC = () => {
  const { admin } = useAuth();
  const navigate = useNavigate();
  const [searchParams] = useSearchParams();
  const [showOther, setShowOther] = useState(false);
  const [otherText, setOtherText] = useState(``);

  const nextParam = searchParams.get(`next`) ?? ``;
  const next =
    nextParam.startsWith(`/`) && nextParam[1] !== `/` && nextParam[1] !== `\\`
      ? nextParam
      : `/`;

  if (!admin) {
    return <Navigate to="/signup" replace />;
  }

  function record(detail: string): void {
    Current.api.logEvent({ eventId: REFERRAL_EVENT_ID, detail }).catch(() => null);
    navigate(next, { replace: true });
  }

  function submitOther(): void {
    const trimmed = otherText.trim();
    record(
      trimmed
        ? `referral source survey: other — "${trimmed}"`
        : `referral source survey: other`,
    );
  }

  return (
    <FullscreenGradientBg>
      <div className="bg-white/20 xs:rounded-3xl backdrop-blur xs:m-4 w-full max-w-2xl px-6 xs:px-8 md:px-12 py-10">
        <h1 className="text-center sm:text-left text-3xl font-semibold text-white mb-8">
          How did you hear about us?
        </h1>
        <div className="flex flex-col gap-3">
          {OPTIONS.map((option) => (
            <OptionButton
              key={option.token}
              icon={option.icon}
              brand={`brand` in option && option.brand === true}
              label={option.label}
              trackConversion
              onClick={() => record(`referral source survey: ${option.token}`)}
            />
          ))}
          {!showOther ? (
            <OptionButton
              icon="fa-comment-dots"
              label="Something else"
              onClick={() => setShowOther(true)}
            />
          ) : (
            <div className="flex flex-col gap-3 bg-white/20 rounded-2xl p-4">
              <input
                autoFocus
                type="text"
                maxLength={280}
                value={otherText}
                onChange={(event) => setOtherText(event.target.value)}
                onKeyDown={(event) => event.key === `Enter` && submitOther()}
                placeholder="Where did you hear about Gertrude?"
                className="w-full px-4 py-3 rounded-xl bg-white/80 text-violet-900 placeholder:text-violet-900/40 outline-none focus:bg-white transition"
              />
              <button
                type="button"
                data-track-conversion
                onClick={submitOther}
                className="self-end px-8 py-2.5 rounded-xl bg-white text-violet-700 font-bold hover:bg-violet-50 active:scale-[0.98] transition"
              >
                Continue
              </button>
            </div>
          )}
        </div>
        <button
          type="button"
          onClick={() => navigate(next, { replace: true })}
          className="block mx-auto sm:mx-0 mt-8 text-white/70 hover:text-white transition-colors"
        >
          Skip
        </button>
      </div>
    </FullscreenGradientBg>
  );
};

export default ReferralSurvey;

interface OptionButtonProps {
  icon: string;
  brand?: boolean;
  label: string;
  trackConversion?: boolean;
  onClick(): void;
}

const OptionButton: React.FC<OptionButtonProps> = ({
  icon,
  brand = false,
  label,
  trackConversion = false,
  onClick,
}) => (
  <button
    type="button"
    data-track-conversion={trackConversion ? true : undefined}
    onClick={onClick}
    className={cx(
      `px-5 py-4 bg-white/20 rounded-2xl flex items-center gap-4 text-left cursor-pointer`,
      `hover:bg-white/30 active:bg-white/40 transition-[background-color,transform] duration-200`,
      `active:scale-[0.98]`,
    )}
  >
    <span className="w-11 h-11 shrink-0 bg-white/20 rounded-full flex justify-center items-center">
      <i className={cx(brand ? `fab` : `fas`, icon, `text-white text-lg`)} />
    </span>
    <span className="text-lg text-white font-medium leading-tight sm:leading-normal">
      {label}
    </span>
  </button>
);
