import React, { useState } from 'react';
import cx from 'classnames';
import { FullscreenGradientBg } from '@dash/components';
import { Button, Loading } from '@shared/components';
import { useNavigate } from 'react-router-dom';
import Error from '@dash/components/src/Modal/Error';
import { Key, useMutation, useQuery } from '../../hooks';
import Current from '../../environment';

type PageType = 'start' | 'parent' | 'peer' | 'self';

const UseCaseSurvey: React.FC = () => {
  const [page, setPage] = useState<PageType>(`start`);
  const [adminId, setAdminId] = useState<UUID | null>(null);
  const navigate = useNavigate();

  const query = useQuery(Key.admin, Current.api.getAdmin, {
    onReceive: (admin) => setAdminId(admin.id),
  });
  const deleteAdmin = useMutation(
    (id: UUID) => Current.api.deleteEntity({ type: `admin`, id }),
    {
      onSuccess: () => {
        navigate(`/`);
      },
    },
  );

  if (query.isLoading) {
    return (
      <FullscreenGradientBg>
        <Loading withWhiteBg />
      </FullscreenGradientBg>
    );
  }

  if (query.isError) {
    return (
      <FullscreenGradientBg>
        <Error />
      </FullscreenGradientBg>
    );
  }

  return (
    <FullscreenGradientBg>
      <div className="bg-white/20 xs:rounded-3xl backdrop-blur xs:m-4">
        <Page type="start" current={page} relative>
          <h1 className="text-3xl font-semibold text-white mb-6">
            How do you intend to use Gertrude?
          </h1>
          <div className="flex flex-col gap-4">
            <Option
              type="link"
              to="/"
              title="I'm a parent wanting to protect my child"
              description="Lorem ipsum dolor sit amet, qui minim labore adipisicing."
              Icon={
                <svg
                  width="70"
                  height="70"
                  viewBox="0 0 70 70"
                  fill="none"
                  xmlns="http://www.w3.org/2000/svg"
                >
                  <path
                    d="M16.0272 36.8116C14.9738 31.1934 19.2839 26 25 26V26C30.7161 26 35.0262 31.1934 33.9728 36.8116L30.6118 54.7372C30.2571 56.629 28.6052 58 26.6803 58H23.3197C21.3948 58 19.7429 56.629 19.3882 54.7372L16.0272 36.8116Z"
                    fill="white"
                    fill-opacity="0.75"
                  />
                  <circle cx="29" cy="19" r="6" fill="white" fill-opacity="0.75" />
                  <path
                    d="M38.9946 44.7762C37.9729 40.2807 41.3898 36 46 36V36C50.6102 36 54.0271 40.2807 53.0054 44.7762L50.7076 54.8865C50.2937 56.7076 48.6747 58 46.8071 58H45.1929C43.3253 58 41.7063 56.7076 41.2924 54.8865L38.9946 44.7762Z"
                    fill="white"
                    fill-opacity="0.55"
                  />
                  <circle cx="46" cy="30" r="5" fill="white" fill-opacity="0.55" />
                  <path
                    d="M36.2392 42.1961C36.1155 41.5773 36.5888 41 37.2198 41H54.7802C55.4112 41 55.8845 41.5773 55.7608 42.1961L54.1608 50.1961C54.0673 50.6635 53.6569 51 53.1802 51H38.8198C38.3431 51 37.9327 50.6635 37.8392 50.1961L36.2392 42.1961Z"
                    fill="#64748B"
                  />
                  <path
                    d="M46.6722 46.2154C46.6711 46.027 46.7593 45.8847 46.9378 45.78C46.8379 45.6419 46.687 45.5659 46.4878 45.551C46.2991 45.5366 46.093 45.6573 46.0175 45.6573C45.9378 45.6573 45.755 45.5561 45.6116 45.5561C45.3151 45.5607 45 45.7846 45 46.2401C45 46.3746 45.0255 46.5136 45.0765 46.657C45.1445 46.8455 45.39 47.3076 45.6461 47.2999C45.78 47.2968 45.8746 47.208 46.0489 47.208C46.2179 47.208 46.3055 47.2999 46.4548 47.2999C46.7131 47.2963 46.9352 46.8763 47 46.6873C46.6536 46.5297 46.6722 46.2252 46.6722 46.2154ZM46.3714 45.3723C46.5165 45.2059 46.5032 45.0544 46.4989 45C46.3709 45.0072 46.2226 45.0842 46.1382 45.1792C46.0452 45.2809 45.9904 45.4067 46.0021 45.5484C46.1408 45.5587 46.2673 45.4899 46.3714 45.3723Z"
                    fill="white"
                  />
                </svg>
              }
            />
            <Option
              type="pageSwitch"
              title="I'm an adult wanting to help out a friend"
              description="Lorem ipsum dolor sit amet, qui minim labore adipisicing."
              toPage="peer"
              setPage={setPage}
              Icon={
                <svg
                  width="70"
                  height="70"
                  viewBox="0 0 70 70"
                  fill="none"
                  xmlns="http://www.w3.org/2000/svg"
                >
                  <path
                    d="M14.0584 36.9781C12.9888 31.2733 17.3652 26 23.1694 26V26C28.8595 26 33.2064 31.0789 32.328 36.7008L29.5285 54.6175C29.2243 56.5646 27.5472 58 25.5765 58H21.3197C19.3948 58 17.7429 56.629 17.3882 54.7372L14.0584 36.9781Z"
                    fill="white"
                    fill-opacity="0.75"
                  />
                  <circle cx="23" cy="19" r="6" fill="white" fill-opacity="0.75" />
                  <path
                    d="M39.0272 36.8116C37.9738 31.1934 42.2839 26 48 26V26C53.7161 26 58.0262 31.1934 56.9728 36.8116L53.6118 54.7372C53.2571 56.629 51.6052 58 49.6803 58H46.3197C44.3948 58 42.7429 56.629 42.3882 54.7372L39.0272 36.8116Z"
                    fill="white"
                    fill-opacity="0.55"
                  />
                  <circle cx="48" cy="19" r="6" fill="white" fill-opacity="0.55" />
                  <path
                    d="M36.2392 37.1961C36.1155 36.5773 36.5888 36 37.2198 36H54.7802C55.4112 36 55.8845 36.5773 55.7608 37.1961L54.1608 45.1961C54.0673 45.6635 53.6569 46 53.1802 46H38.8198C38.3431 46 37.9327 45.6635 37.8392 45.1961L36.2392 37.1961Z"
                    fill="#64748B"
                  />
                  <path
                    d="M46.6722 41.2154C46.6711 41.027 46.7593 40.8847 46.9378 40.78C46.8379 40.6419 46.687 40.5659 46.4878 40.551C46.2991 40.5366 46.093 40.6573 46.0175 40.6573C45.9378 40.6573 45.755 40.5561 45.6116 40.5561C45.3151 40.5607 45 40.7846 45 41.2401C45 41.3746 45.0255 41.5136 45.0765 41.657C45.1445 41.8455 45.39 42.3076 45.6461 42.2999C45.78 42.2968 45.8746 42.208 46.0489 42.208C46.2179 42.208 46.3055 42.2999 46.4548 42.2999C46.7131 42.2963 46.9352 41.8763 47 41.6873C46.6536 41.5297 46.6722 41.2252 46.6722 41.2154ZM46.3714 40.3723C46.5165 40.2059 46.5032 40.0544 46.4989 40C46.3709 40.0072 46.2226 40.0842 46.1382 40.1792C46.0452 40.2809 45.9904 40.4067 46.0021 40.5484C46.1408 40.5587 46.2673 40.4899 46.3714 40.3723Z"
                    fill="white"
                  />
                </svg>
              }
            />
            <Option
              type="pageSwitch"
              title="I'm trying to help myself with bad habits"
              description="Lorem ipsum dolor sit amet, qui minim labore adipisicing."
              toPage="self"
              setPage={setPage}
              className="mb-4"
              Icon={
                <svg
                  width="70"
                  height="70"
                  viewBox="0 0 70 70"
                  fill="none"
                  xmlns="http://www.w3.org/2000/svg"
                >
                  <path
                    d="M27.0272 36.8116C25.9738 31.1934 30.2839 26 36 26V26C41.7161 26 46.0262 31.1934 44.9728 36.8116L41.6118 54.7372C41.2571 56.629 39.6052 58 37.6803 58H34.3197C32.3948 58 30.7429 56.629 30.3882 54.7372L27.0272 36.8116Z"
                    fill="white"
                    fill-opacity="0.75"
                  />
                  <circle cx="36" cy="19" r="6" fill="white" fill-opacity="0.75" />
                  <path
                    d="M24.2392 36.1961C24.1155 35.5773 24.5888 35 25.2198 35H42.7802C43.4112 35 43.8845 35.5773 43.7608 36.1961L42.1608 44.1961C42.0673 44.6635 41.6569 45 41.1802 45H26.8198C26.3431 45 25.9327 44.6635 25.8392 44.1961L24.2392 36.1961Z"
                    fill="#64748B"
                  />
                  <path
                    d="M34.6722 40.2154C34.6711 40.027 34.7593 39.8847 34.9378 39.78C34.8379 39.6419 34.687 39.5659 34.4878 39.551C34.2991 39.5366 34.093 39.6573 34.0175 39.6573C33.9378 39.6573 33.755 39.5561 33.6116 39.5561C33.3151 39.5607 33 39.7846 33 40.2401C33 40.3746 33.0255 40.5136 33.0765 40.657C33.1445 40.8455 33.39 41.3076 33.6461 41.2999C33.78 41.2968 33.8746 41.208 34.0489 41.208C34.2179 41.208 34.3055 41.2999 34.4548 41.2999C34.7131 41.2963 34.9352 40.8763 35 40.6873C34.6536 40.5297 34.6722 40.2252 34.6722 40.2154ZM34.3714 39.3723C34.5165 39.2059 34.5032 39.0544 34.4989 39C34.3709 39.0072 34.2226 39.0842 34.1382 39.1792C34.0452 39.2809 33.9904 39.4067 34.0021 39.5484C34.1408 39.5587 34.2673 39.4899 34.3714 39.3723Z"
                    fill="white"
                  />
                </svg>
              }
            />
          </div>
        </Page>
        <Page type="peer" current={page}>
          <div className="w-full h-full flex flex-col justify-center items-center xs:p-4">
            <h1 className="text-3xl xs:text-4xl font-semibold text-white text-center">
              Great, Gertrude is perfect for you!
            </h1>
            <p className="text-center text-xl xs:text-2xl text-white/70 mb-8 mt-4">
              Just be aware that we use parent/child language, etc. Lorem ipsum dolor sit
              amet, qui minim labore.
            </p>
            <Button type="link" color="primary" to="/" size="large">
              Get started
              <i className="ml-3 fas fa-arrow-right" />
            </Button>
          </div>
        </Page>
        <Page type="self" current={page}>
          <div className="w-full h-full flex flex-col justify-center items-center xs:p-4">
            <h1 className="text-4xl font-semibold text-white text-center mb-8">
              Sorry, we don't support that use case yet
            </h1>
            {deleteAdmin.isIdle && (
              <Button
                type="button"
                color="primary"
                onClick={() => deleteAdmin.mutate(adminId ?? ``)}
                size="large"
              >
                Delete my account
                <i className="ml-3 fas fa-arrow-right" />
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
  title: string;
  Icon: React.ReactNode;
  description: string;
  className?: string;
} & (
  | { type: `link`; to: string }
  | { type: `pageSwitch`; toPage: PageType; setPage(page: PageType): void }
);

const Option: React.FC<OptionProps> = ({
  title,
  Icon,
  description,
  className,
  ...props
}) => {
  const navigate = useNavigate();
  return (
    <button
      onClick={() => {
        if (props.type === `link`) {
          navigate(props.to);
          return;
        }
        props.setPage(props.toPage);
      }}
      className={cx(
        `p-6 bg-white/20 rounded-3xl flex flex-col md:flex-row items-center gap-4 cursor-pointer hover:bg-white/30 transition-[background-color,transform] duration-300 active:scale-95 md:pr-12 active:bg-white/40`,
        className,
      )}
    >
      <div className="w-[60px] sm:w-[70px] h-[60px] sm:h-[70px] bg-white/20 rounded-full flex justify-center items-center [&>*]:scale-[90%]">
        {Icon}
      </div>
      <div className="flex flex-col items-center md:!items-start">
        <h1 className="text-xl sm:text-2xl font-semibold text-violet-900/80">{title}</h1>
        <p className="text-violet-900/70">{description}</p>
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
