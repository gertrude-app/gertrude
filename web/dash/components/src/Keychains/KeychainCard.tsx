import React from 'react';
import cx from 'classnames';
import { inflect } from '@dash/utils';
import PillBadge from '../PillBadge';
import GradientIcon from '../GradientIcon';

type Props =
  | ({
      mode: 'list';
      onRemove(): unknown;
      removeText: string;
      editUrl?: string;
    } & Common)
  | ({
      mode: 'select';
      selected: boolean;
      onSelect(): unknown;
    } & Common);

type Common = {
  name: string;
  description?: string;
  numKeys: number;
  isPublic: boolean;
};

const KeychainCard: React.FC<Props> = ({
  isPublic,
  name,
  numKeys,
  description,
  ...props
}) => (
  <div
    className={cx(
      `rounded-xl shadow-lg border-[0.5px] bg-white flex flex-col justify-between transition duration-100`,
      isSelect(props) && props.selected && `bg-violet-50 border-violet-300`,
      isSelect(props) && !props.selected && `hover:bg-gray-50 cursor-pointer`,
      isSelect(props) && `min-h-[77px]`,
    )}
    onClick={isSelect(props) ? props.onSelect : undefined}
    data-test="keychain-card"
  >
    <div className="flex items-stretch flex-grow">
      <div
        className={cx(
          `w-16 xs:w-20 shrink-0 py-4 flex justify-center mr-2`,
          isSelect(props) && `items-center`,
        )}
      >
        <GradientIcon icon="list" size="medium" className="mx-0" />
      </div>
      <div className="pr-4 py-4 flex flex-col justify-center flex-grow">
        <div className="flex flex-col md:flex-row justify-between md:items-center relative right-0">
          <h2 className="text-left font-semibold text-lg leading-6 text-gray-900 sm:whitespace-normal">
            {name}
          </h2>
          <div className="flex md:justify-end pt-1 md:pt-0 items-center shrink-0 space-x-2 flex-grow">
            <h4 className="text-gray-500 shrink-0">
              {numKeys}
              {` `}
              {inflect(`key`, numKeys)}
            </h4>
            {isSelect(props) && isPublic && (
              <PillBadge small type="green">
                Public
              </PillBadge>
            )}
          </div>
        </div>
        {isSelect(props) || (
          <p
            className={cx(
              description ? `text-gray-600 leading-tight` : `text-gray-400 italic`,
              `mt-1.5 mb-1`,
            )}
          >
            {description || `No description`}
          </p>
        )}
      </div>
    </div>
    {isSelect(props) || (
      <div
        className={cx(
          `bg-gray-50 rounded-b-xl w-full flex justify-between`,
          isSelect(props) && props.selected && `bg-indigo-100/40`,
        )}
      >
        <div className="flex-grow ml-3">
          <PillBadge
            type="green"
            className={cx(
              `border my-2`,
              !isPublic && `opacity-0`, // ensure equal heights
            )}
          >
            <i className="fa-solid fa-users mr-1 text-sm" /> Public
          </PillBadge>
        </div>
        {props.mode === `list` && (
          <div className="flex items-stretch">
            {props.editUrl && (
              <a
                className="font-medium hover:bg-gray-100 px-4 py-2 cursor-pointer text-gray-600 transition duration-100 select-none flex items-center"
                href={props.editUrl}
                data-test="edit-keychain"
              >
                Edit
              </a>
            )}
            <button
              className="font-medium hover:bg-gray-100 px-4 py-2 cursor-pointer text-red-600 transition duration-100 rounded-br-xl"
              onClick={props.onRemove}
              data-test="remove-keychain"
            >
              {props.removeText}
            </button>
          </div>
        )}
      </div>
    )}
  </div>
);

export default KeychainCard;

function isSelect(props: { mode: Props['mode'] }): props is {
  mode: 'select';
} & Common {
  return props.mode === `select`;
}
