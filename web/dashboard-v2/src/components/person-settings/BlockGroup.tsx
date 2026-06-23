import { Badge } from '@gertrude/ui';
import cx from 'clsx';
import { CheckIcon, CircleQuestionMarkIcon } from 'lucide-react';
import React, { useState } from 'react';

const BlockGroup: React.FC<{
  title: string;
  shortDescription: string;
  longExplanation: string;
  blocked: boolean;
  setBlocked: (blocked: boolean) => void;
}> = ({ title, shortDescription, longExplanation, blocked, setBlocked }) => {
  const [expanded, setExpanded] = useState(false);

  return (
    <div
      className="flex flex-col border-t first:border-t-0 border-stone-200 py-3 px-4 hover:bg-stone-50 cursor-pointer"
      onClick={() => setBlocked(!blocked)}
    >
      <div className="flex flex-row items-center justify-between gap-2">
        <div className="flex items-center gap-4">
          <div
            className={cx(
              `w-5 h-5 rounded-full border flex items-center justify-center shrink-0`,
              blocked ? `bg-violet-500 border-violet-500` : `bg-white border-stone-200`,
            )}
          >
            <CheckIcon
              className="w-3.5 h-3.5 text-white translate-y-[0.5px]"
              strokeWidth={3}
            />
          </div>
          <div className="flex flex-col">
            <div className="flex items-center gap-2">
              <span className="text-stone-900">{title}</span>
              <Badge size="small" color={blocked ? `violet` : `neutral`}>
                {blocked ? `Blocked` : `Not Blocked`}
              </Badge>
            </div>
            <span className="text-sm text-stone-600">{shortDescription}</span>
          </div>
        </div>
        <button
          className="hover:bg-stone-200/50 w-7 h-7 flex justify-center items-center rounded-full cursor-pointer group"
          onClick={(e) => {
            e.stopPropagation();
            setExpanded(!expanded);
          }}
        >
          <CircleQuestionMarkIcon className="text-stone-400 w-5 h-5 group-hover:text-stone-500" />
        </button>
      </div>
      <div
        className={cx(
          `overflow-hidden transition-[height,opacity] duration-100`,
          expanded ? `h-auto opacity-100` : `h-0 opacity-0`,
        )}
      >
        <p className="text-sm text-stone-500 ml-9 mt-2">{longExplanation}</p>
      </div>
    </div>
  );
};

export default BlockGroup;
