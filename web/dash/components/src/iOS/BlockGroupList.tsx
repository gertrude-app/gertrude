import React, { useState } from 'react';

export type BlockGroupData = {
  id: UUID;
  name: string;
  description: string;
  longDescription: string;
};

type Props = {
  groups: BlockGroupData[];
  enabledGroupIds: readonly UUID[];
  onToggle(id: UUID): void;
  title?: string;
};

const BlockGroupList: React.FC<Props> = ({
  groups,
  enabledGroupIds,
  onToggle,
  title = `Block Groups`,
}) => (
  <div>
    <h2 className="text-lg font-bold text-slate-700 mb-3">{title}</h2>
    <div className="bg-white rounded-xl p-5 border-[0.5px] border-slate-200 shadow shadow-slate-300/50 space-y-2">
      {groups.map((group) => (
        <BlockGroupItem
          key={group.id}
          group={group}
          enabled={enabledGroupIds.includes(group.id)}
          onToggle={() => onToggle(group.id)}
        />
      ))}
    </div>
  </div>
);

const BlockGroupItem: React.FC<{
  group: BlockGroupData;
  enabled: boolean;
  onToggle: () => void;
}> = ({ group, enabled, onToggle }) => {
  const [expanded, setExpanded] = useState(false);
  return (
    <div
      className={`rounded-xl overflow-hidden transition duration-100 ${
        enabled ? `bg-violet-50` : `hover:bg-slate-50`
      }`}
    >
      <div className="flex">
        <button
          className="flex flex-grow text-left rounded-xl outline-none focus-visible:ring-2 focus-visible:ring-violet-400 transition duration-100"
          onClick={onToggle}
        >
          <div className="w-12 self-stretch flex flex-shrink-0 justify-center items-start pt-3.5">
            <div
              className={`rounded-full flex justify-center items-center text-white transition-[width,border-width,border] ${
                enabled
                  ? `border-none w-6 h-6 bg-gradient-to-br from-indigo-500 to-fuchsia-500`
                  : `w-5 h-5 border-2`
              }`}
            >
              <i className="fa-solid fa-check text-sm" />
            </div>
          </div>
          <div className="flex-grow pt-3 pb-2.5 pr-2">
            <div className="flex items-center gap-2">
              <h3 className="font-bold leading-tight">{group.name}</h3>
              <span
                className={`text-xs font-semibold px-2 py-0.5 rounded-full ${
                  enabled
                    ? `bg-violet-200 text-violet-800`
                    : `bg-slate-200 text-slate-500`
                }`}
              >
                {enabled ? `Blocked` : `Not blocked`}
              </span>
            </div>
            <p className="text-slate-500 text-sm mt-0.5 leading-snug">
              {group.description}
            </p>
          </div>
        </button>
        {group.longDescription && (
          <button
            type="button"
            className={`flex-shrink-0 self-center mr-3 w-8 h-8 flex items-center justify-center rounded-full transition ${
              expanded
                ? `text-violet-600 bg-violet-100`
                : `text-violet-400 hover:text-violet-600 hover:bg-violet-100/60`
            }`}
            onClick={() => setExpanded(!expanded)}
          >
            <i className="fa-solid fa-circle-question text-[15px]" />
          </button>
        )}
      </div>
      {expanded && (
        <p className="text-slate-500 text-sm italic leading-snug border-l-2 border-violet-200 pl-3 -mt-0.5 ml-12 mr-3 mb-4">
          {group.longDescription}
        </p>
      )}
    </div>
  );
};

export default BlockGroupList;
