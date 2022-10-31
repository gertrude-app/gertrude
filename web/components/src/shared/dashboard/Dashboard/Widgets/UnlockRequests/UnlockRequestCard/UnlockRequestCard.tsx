import React from 'react';
import cx from 'classnames';
import Button from '../../../../../Button';
import GradientIcon from '../../../../GradientIcon';
import UserInputText from '../../../../Keychains/Keys/KeyCreator/UserInputText';
import { relativeTime } from '../../../../lib/dates';
import { RequestStatus } from '../../../../types/GraphQL';

type Props = {
  id: UUID;
  url: string;
  userName: string;
  status: RequestStatus;
  comment?: string;
  createdAt: string;
};

const UnlockRequestCard: React.FC<Props> = ({
  id,
  url,
  userName,
  comment,
  status,
  createdAt,
}) => (
  <div
    className={cx(`flex flex-col bg-white border p-4 rounded-xl shadow-lg max-w-3xl`, {
      'border-red-600/30': status === RequestStatus.rejected,
      'border-green-700/40': status === RequestStatus.accepted,
    })}
  >
    <div className="flex justify-between items-start mb-4">
      <h2 className="font-bold text-gray-900">{userName}</h2>
      <h3 className="text-gray-400 text-sm">{relativeTime(new Date(createdAt))}</h3>
    </div>
    <div className="py-3 px-5 bg-violet-50 rounded-xl mt-2 flex justify-center items-center">
      <h2 className="font-mono text-base whitespace-nowrap truncate">
        {url.replace(/^https?:\/\//, ``).replace(/\/$/, ``)}
      </h2>
    </div>
    {comment && (
      <div className="flex justify-center items-center mt-3">
        <p className="text-center text-gray-500 text-sm sm:text-base">
          &ldquo;{comment}&rdquo;
        </p>
      </div>
    )}
    {status === RequestStatus.pending ? (
      <div className="flex flex-row space-x-3 items-stretch mt-4 w-full">
        <Button
          type="link"
          to={`/unlock-requests/${id}`}
          color="secondary-white"
          small
          fullWidth
        >
          Deny
        </Button>
        <Button
          type="link"
          to={`/unlock-requests/${id}`}
          color="primary-violet"
          className="whitespace-nowrap"
          small
          fullWidth
        >
          Accept &rarr;
        </Button>
      </div>
    ) : (
      <div className="mt-auto pt-4 flex items-center justify-center space-x-2">
        <GradientIcon
          className="translate-x-1 scale-75"
          size="medium"
          icon={status === RequestStatus.accepted ? `thumbs-up` : `thumbs-down`}
        />
        <span className="text-gray-600">Unlock request</span>
        <UserInputText small className="translate-y-0.5">
          {status === RequestStatus.accepted ? `accepted` : `rejected`}
        </UserInputText>
        .
      </div>
    )}
  </div>
);

export default UnlockRequestCard;
