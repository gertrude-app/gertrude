import React, { useState } from 'react';
import cx from 'classnames';
import { FullscreenGradientBg } from '@dash/components';
import { Button } from '@shared/components';
import { Navigate, useNavigate } from 'react-router-dom';
import { useAuth, useMutation } from '../../hooks';
import Current from '../../environment';

type PageType = 'start' | 'adult-peer' | 'self';

const UseCaseSurvey: React.FC = () => {
  const [page, setPage] = useState<PageType>(`start`);
  const { admin, logout } = useAuth();

  const deleteAdmin = useMutation(
    (id: UUID) => Current.api.deleteEntity({ type: `admin`, id }),
    { onSuccess: () => setTimeout(() => logout(), 3000) },
  );

  if (!admin) {
    return <Navigate to="/signup" />;
  }

  return (
    <FullscreenGradientBg>
      <div className="bg-white/20 xs:rounded-3xl backdrop-blur xs:m-4">
        <Page type="start" current={page} relative>
          <h1 className="text-center sm:text-left text-3xl font-semibold text-white mb-6">
            How do you want to use Gertrude?
          </h1>
          <div className="flex flex-col gap-4">
            <Option
              type="parent-child"
              setPage={setPage}
              description="I’m a mom/dad concerned about internet safety for my kids"
            >
              I’m a <b>parent</b> wanting to protect my <b>child</b>
            </Option>
            <Option
              type="adult-peer"
              setPage={setPage}
              description="Like an accountability partner, a spouse, or fiancé"
            >
              I’m an <b>adult</b> wanting to help out a <b>friend</b>
            </Option>
            <Option
              type="self"
              setPage={setPage}
              description="Perhaps to break habits, avoid websites, or something else"
            >
              I’m wanting to help <b>myself</b>
            </Option>
          </div>
        </Page>
        <Page type="adult-peer" current={page}>
          <div className="w-full h-full flex flex-col justify-center items-center xs:p-4">
            <h1 className="text-3xl xs:text-4xl font-semibold text-white text-center">
              Great, Gertrude is perfect for you!
            </h1>
            <p className="text-center text-xl xs:text-2xl [&>em]:underline [&>b]:text-white text-white/70 mb-8 mt-4">
              Just be aware that for simplicity, we use{` `}
              <b>parent/child language</b> throughout the app. So whenever you see{` `}
              <b>“Parent”</b>&mdash;that's <em>you</em>, and when you see <b>“Child”</b>
              &mdash;that's the <em>friend</em> you're helping.
            </p>
            <Button type="link" color="primary" to="/" size="large">
              Get started
              <i className="ml-3 fas fa-arrow-right" />
            </Button>
          </div>
        </Page>
        <Page type="self" current={page}>
          <div className="w-full h-full flex flex-col justify-center items-center xs:p-4">
            <h1 className="text-4xl font-semibold text-white text-center mb-4">
              Gertrude probably isn’t a good fit for you&hellip;
            </h1>
            <p className="text-center text-xl xs:text-2xl [&>em]:underline [&>b]:text-white text-white/70 mb-8 mt-4">
              Gertrude requires two distinct <b>roles</b>&mdash;usually a parent and a
              child. It is not designed to be used by one person alone.
            </p>
            <Button
              className="mb-4 inline-block"
              type="external"
              href="https://gertrude.app/contact"
              color="primary"
              size="large"
            >
              Contact support
              <i className="mx-3 fas fa-question-circle" />
            </Button>
            <Button
              className="mb-4 inline-block"
              type="link"
              to="/"
              color="secondary"
              size="large"
            >
              Continue anyway
              <i className="ml-4 fas fa-arrow-right" />
            </Button>
            {deleteAdmin.isIdle && (
              <Button
                type="button"
                color="secondary"
                onClick={() => deleteAdmin.mutate(admin.id)}
                size="large"
              >
                Delete my account
                <i className="ml-2 fas fa-trash" />
              </Button>
            )}
            {deleteAdmin.isPending && (
              <p className="text-white/80 text-lg">Deleting account...</p>
            )}
            {deleteAdmin.isError && (
              <p className="text-white/80 text-lg text-center">
                Hmm, something went wrong. Refresh the page and try again.
              </p>
            )}
            {deleteAdmin.isSuccess && (
              <p className="text-white/80 text-lg">Account deleted!</p>
            )}
          </div>
        </Page>
      </div>
    </FullscreenGradientBg>
  );
};

export default UseCaseSurvey;

type OptionProps = {
  type: 'parent-child' | 'adult-peer' | 'self';
  children: React.ReactNode;
  description: string;
  setPage(page: PageType): unknown;
};

const Option: React.FC<OptionProps> = ({ children, type, description, setPage }) => {
  const navigate = useNavigate();
  return (
    <button
      onClick={() => {
        Current.api.logEvent({
          eventId: `bc6213cb`,
          detail: `signup use-case survey click: *${type.toUpperCase()}*`,
        });
        if (type === `parent-child`) {
          navigate(`/`);
        } else {
          setPage(type);
        }
      }}
      className={cx(
        `px-10 sm:px-6 py-6 bg-white/20 rounded-3xl flex flex-col md:flex-row items-center gap-4 cursor-pointer hover:bg-white/30 transition-[background-color,transform] duration-300 active:scale-95 md:pr-12 active:bg-white/40`,
      )}
    >
      <div className="w-[60px] sm:w-[70px] h-[60px] sm:h-[70px] bg-white/20 rounded-full flex justify-center items-center [&>*]:scale-[90%]">
        <img src={`/use-case-icons/${type}.svg`} alt="" />
      </div>
      <div className="flex flex-col items-center md:items-start">
        <h1 className="text-xl sm:text-2xl text-violet-900/80 mb-0.5">{children}</h1>
        <p className="text-violet-900/60 antialiased">{description}</p>
      </div>
    </button>
  );
};

interface PageProps {
  children: React.ReactNode;
  type: PageType;
  current: PageType;
  relative?: boolean;
}

const Page: React.FC<PageProps> = ({ children, type, current, relative }) => (
  <div
    className={cx(
      type === current ? `opacity-100` : `opacity-0 translate-y-4 pointer-events-none`,
      `transition-[opacity,transform] duration-300 px-6 xs:px-8 py-12 md:px-12`,
      relative ? `relative` : `absolute w-full h-full left-0 top-0`,
    )}
  >
    {children}
  </div>
);
