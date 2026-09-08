import { formatDate } from '@dash/datetime';
import cx from 'classnames';
import React from 'react';

const TrialStatusCard: React.FC<{
  heading: React.ReactNode;
  children: React.ReactNode;
  className?: string;
}> = ({ heading, children, className }) => (
  <div
    className={cx(`rounded-xl border border-slate-200 bg-slate-50 px-5 py-4`, className)}
  >
    <p className="font-semibold text-slate-800">{heading}</p>
    <div className="mt-1 text-sm text-slate-600">{children}</div>
  </div>
);

export default TrialStatusCard;

type MusicTrialStatusCardProps =
  | { status: `ready`; deviceLabel: string; className?: string }
  | { status: `active`; expiresAt: string; className?: string };

export const MusicTrialStatusCard: React.FC<MusicTrialStatusCardProps> = (props) => {
  const price = (
    <>
      Gertrude Music is <b>$5/month for the whole family</b>. You won&rsquo;t be charged
      automatically.
    </>
  );

  return (
    <TrialStatusCard
      className={props.className}
      heading={
        props.status === `ready` ? `Music Free Trial Ready` : `Music Free Trial Active`
      }
    >
      {props.status === `ready` ? (
        <>
          Next, open Gertrude Music on {props.deviceLabel}. The 21-day free trial will
          begin automatically. When the trial ends, {price}
        </>
      ) : (
        <>
          After {formatDate(new Date(props.expiresAt), `long`)}, {price}
        </>
      )}
    </TrialStatusCard>
  );
};
