import { type RequestGroup, groupRequestsByKey, naughtyInfo } from '@dash/keys';
import {
  AdjustmentsHorizontalIcon,
  InformationCircleIcon,
} from '@heroicons/react/24/outline';
import { CheckIcon, XMarkIcon } from '@heroicons/react/24/solid';
import { Badge, Button } from '@shared/components';
import cx from 'classnames';
import React, { useEffect, useMemo, useState } from 'react';
import type { HandleUnlockRequests, KeychainSummary, UnlockRequest } from '@dash/types';
import PageHeading from '../PageHeading';

type AddressType = `standard` | `strict`;

type Decision = `accept` | `reject` | `undecided`;

type RowState = {
  decision: Decision;
  keychainId: UUID;
  keychainOverridden: boolean;
  addressType: AddressType;
  expiration: string | undefined;
  comment: string | undefined;
};

type Props = {
  childName: string;
  requests: UnlockRequest[];
  keychains: KeychainSummary[];
  onSubmit?: (input: HandleUnlockRequests.Input, numUndecided: number) => void;
  submitting?: boolean;
};

function defaultAddressType(key: RequestGroup[`key`]): AddressType {
  return key.type === `anySubdomain` ? `standard` : `strict`;
}

function hasDomainScope(key: RequestGroup[`key`]): boolean {
  return key.type === `domain` || key.type === `anySubdomain`;
}

const BatchUnlockRequests: React.FC<Props> = ({
  childName,
  requests,
  keychains,
  onSubmit,
  submitting,
}) => {
  const groups = useMemo(() => groupRequestsByKey(requests), [requests]);

  const bestKeychainId = keychains[0]?.id ?? ``;
  const [globalKeychainId, setGlobalKeychainId] = useState(bestKeychainId);
  const [rows, setRows] = useState<Record<UUID, RowState>>(() =>
    Object.fromEntries(
      groups.map((g) => {
        const naughty = naughtyInfo(g);
        const decision: Decision = naughty
          ? naughty.level === `deny`
            ? `reject`
            : `undecided`
          : `accept`;
        return [
          g.representative.id,
          {
            decision,
            keychainId: bestKeychainId,
            keychainOverridden: false,
            addressType: defaultAddressType(g.key),
            expiration: undefined,
            comment: undefined,
          },
        ];
      }),
    ),
  );
  useEffect(() => {
    setRows((prev) => {
      const newEntries: Record<UUID, RowState> = {};
      let hasNew = false;
      for (const g of groups) {
        const id = g.representative.id;
        if (!prev[id]) {
          hasNew = true;
          const naughty = naughtyInfo(g);
          const decision: Decision = naughty
            ? naughty.level === `deny`
              ? `reject`
              : `undecided`
            : `accept`;
          newEntries[id] = {
            decision,
            keychainId: globalKeychainId,
            keychainOverridden: false,
            addressType: defaultAddressType(g.key),
            expiration: undefined,
            comment: undefined,
          };
        }
      }
      return hasNew ? { ...prev, ...newEntries } : prev;
    });
  }, [groups, globalKeychainId]);

  const getRow = (id: UUID): RowState =>
    rows[id] ?? {
      decision: `undecided`,
      keychainId: bestKeychainId,
      keychainOverridden: false,
      addressType: `strict`,
      expiration: undefined,
      comment: undefined,
    };

  const [expandedEdit, setExpandedEdit] = useState<UUID | null>(null);
  const [expandedInfo, setExpandedInfo] = useState<UUID | null>(null);
  const [denyComment, setDenyComment] = useState(``);

  const changeGlobalKeychain = (keychainId: UUID): void => {
    setGlobalKeychainId(keychainId);
    setRows((prev) => {
      const next = { ...prev };
      for (const g of groups) {
        const cur = next[g.representative.id];
        if (cur && !cur.keychainOverridden) {
          next[g.representative.id] = { ...cur, keychainId };
        }
      }
      return next;
    });
  };

  const updateRow = (id: UUID, update: Partial<RowState>): void => {
    setRows((prev) => {
      const cur = prev[id];
      return cur ? { ...prev, [id]: { ...cur, ...update } } : prev;
    });
  };

  const acceptCount = groups.filter(
    (g) => rows[g.representative.id]?.decision === `accept`,
  ).length;
  const rejectCount = groups.filter(
    (g) => rows[g.representative.id]?.decision === `reject`,
  ).length;

  const setAllDecisions = (decision: Decision): void => {
    setRows((prev) => {
      const next = { ...prev };
      for (const g of groups) {
        const cur = next[g.representative.id];
        if (cur) next[g.representative.id] = { ...cur, decision };
      }
      return next;
    });
  };

  const handleSubmit = (): void => {
    if (!onSubmit) return;
    const allDuplicateIds: UUID[] = [];
    const decisions: HandleUnlockRequests.Input[`decisions`] = groups
      .map((group) => {
        const request = group.representative;
        const rs = getRow(request.id);
        if (rs.decision === `undecided`) return null;
        allDuplicateIds.push(...group.duplicateIds);
        if (rs.decision === `accept`) {
          const baseKey = group.key;
          const key =
            hasDomainScope(baseKey) && rs.addressType !== defaultAddressType(baseKey)
              ? rs.addressType === `strict` && baseKey.type === `anySubdomain`
                ? { ...baseKey, type: `domain` as const }
                : rs.addressType === `standard` && baseKey.type === `domain`
                  ? { ...baseKey, type: `anySubdomain` as const }
                  : baseKey
              : baseKey;
          return {
            unlockRequestId: request.id,
            status: `accepted` as const,
            key: {
              keychainId: rs.keychainId,
              key,
              comment: rs.comment,
              expiration: rs.expiration
                ? (`${rs.expiration}T00:00:00.000Z` as ISODateString)
                : undefined,
            },
          };
        }
        return {
          unlockRequestId: request.id,
          status: `rejected` as const,
          responseComment: denyComment || undefined,
        };
      })
      .filter((d): d is NonNullable<typeof d> => d !== null);
    const numUndecided = groups.filter(
      (g) => getRow(g.representative.id).decision === `undecided`,
    ).length;
    onSubmit({ decisions, duplicateRequestIds: allDuplicateIds }, numUndecided);
  };

  const targetLabel = (r: UnlockRequest): string =>
    r.domain ??
    r.url?.replace(/^https?:\/\//, ``).replace(/\/$/, ``) ??
    r.ipAddress ??
    `unknown`;

  const typeLabel = (group: RequestGroup): { label: string; isApp: boolean } => {
    if (group.key.scope.type !== `webBrowsers`) {
      return { label: `App`, isApp: true };
    }
    return { label: `Web`, isApp: false };
  };

  const undecidedCount = groups.filter(
    (g) => rows[g.representative.id]?.decision === `undecided`,
  ).length;

  return (
    <div className="flex flex-col @container">
      <PageHeading icon="unlock">{childName}&rsquo;s unlock requests</PageHeading>

      {groups.length > 1 && (
        <p className="text-base text-slate-500 mt-5 px-1">
          {groups.length} requests are pending. We&rsquo;ve pre-filled recommended
          actions, but please review each one before submitting.
        </p>
      )}

      {keychains.length > 1 && groups.length > 1 && (
        <div className="mt-6 flex flex-col sm:flex-row sm:items-center gap-1.5 sm:gap-3 px-1">
          <label className="text-sm font-medium text-slate-500 whitespace-nowrap">
            Default keychain:
          </label>
          <select
            value={globalKeychainId}
            onChange={(e) => changeGlobalKeychain(e.target.value)}
            className="border border-slate-200 rounded-lg pl-3 pr-8 py-1.5 text-sm text-slate-700 bg-white cursor-pointer focus:outline-none focus:ring-2 focus:ring-violet-500 focus:border-violet-500 truncate w-full sm:w-auto sm:max-w-xs"
          >
            {keychains.map((kc) => (
              <option key={kc.id} value={kc.id}>
                {kc.name} ({kc.numKeys} keys)
              </option>
            ))}
          </select>
        </div>
      )}

      {/* mobile card layout */}
      <div className="mt-6 space-y-3 @[720px]:hidden">
        {groups.map((group) => {
          const request = group.representative;
          const row = getRow(request.id);
          const { label: type, isApp } = typeLabel(group);
          const infoExpanded = expandedInfo === request.id;
          return (
            <div
              key={request.id}
              className={cx(
                `rounded-2xl border overflow-hidden transition-colors`,
                row.decision === `reject` ? `border-red-200/60` : `border-slate-200`,
              )}
            >
              <div className="p-4">
                <div
                  className={cx(
                    `flex items-center gap-2`,
                    request.appName || request.requestComment ? `mb-1` : `mb-3`,
                  )}
                >
                  <Badge type={isApp ? `yellow` : `blue`} size="small">
                    {type}
                  </Badge>
                  <span className="font-mono text-sm text-slate-900 truncate">
                    {targetLabel(request)}
                  </span>
                  {group.allRequests.length > 1 && (
                    <span className="shrink-0 text-xs text-slate-400 bg-slate-100 rounded-full px-2 py-0.5">
                      {group.allRequests.length} requests
                    </span>
                  )}
                </div>

                {(request.appName || request.requestComment) && (
                  <p className="text-sm @[720px]:text-xs text-slate-400 mb-3 @[720px]:mb-2 mt-2.5 @[720px]:mt-0 ml-1">
                    {request.appName && (
                      <span className="text-violet-400">{request.appName}</span>
                    )}
                    {request.appName && request.requestComment && ` · `}
                    {request.requestComment && (
                      <span className="italic">
                        &ldquo;{request.requestComment}&rdquo;
                      </span>
                    )}
                  </p>
                )}

                <NaughtyWarning group={group} />

                <div className="flex items-center gap-2 mb-3">
                  <button
                    onClick={() => {
                      setExpandedInfo(infoExpanded ? null : request.id);
                      if (expandedEdit === request.id) setExpandedEdit(null);
                    }}
                    className={cx(
                      `flex-1 flex items-center justify-center gap-2 rounded-xl border py-2.5 transition-colors`,
                      infoExpanded
                        ? `border-violet-300 bg-violet-50 text-violet-600`
                        : `border-slate-200 bg-white text-slate-400 active:bg-violet-50 active:text-violet-500`,
                    )}
                  >
                    <InformationCircleIcon className="w-5 h-5" />
                  </button>
                  {row.decision !== `reject` && (
                    <button
                      onClick={() => {
                        setExpandedEdit(expandedEdit === request.id ? null : request.id);
                        if (infoExpanded) setExpandedInfo(null);
                      }}
                      className={cx(
                        `flex-1 flex items-center justify-center gap-2 rounded-xl border py-2.5 transition-colors`,
                        expandedEdit === request.id
                          ? `border-violet-300 bg-violet-50 text-violet-600`
                          : `border-slate-200 bg-white text-slate-400 active:bg-violet-50 active:text-violet-500`,
                      )}
                    >
                      <AdjustmentsHorizontalIcon className="w-5 h-5" />
                    </button>
                  )}
                </div>

                {infoExpanded && (
                  <div className="pb-3 border-t border-slate-100 pt-3">
                    <InfoPanel request={request} group={group} />
                  </div>
                )}
                {expandedEdit === request.id && (
                  <div className="pb-3 pt-1">
                    <EditPanel
                      keyRecord={group.key}
                      row={row}
                      onUpdate={(update) => updateRow(request.id, update)}
                    />
                  </div>
                )}

                <div className={cx(`mb-3`, row.decision === `reject` && `hidden`)}>
                  <KeychainSelect
                    keychains={keychains}
                    value={row.keychainId}
                    disabled={false}
                    overridden={row.keychainOverridden}
                    onChange={(keychainId) =>
                      updateRow(request.id, {
                        keychainId,
                        keychainOverridden: keychainId !== globalKeychainId,
                      })
                    }
                  />
                </div>

                <DecisionButtons
                  decision={row.decision}
                  onToggle={(decision) => updateRow(request.id, { decision })}
                  fullWidth
                />
              </div>
            </div>
          );
        })}
      </div>

      {/* desktop table layout */}
      <div className="mt-6 bg-white rounded-t-2xl border border-b-0 border-slate-200 shadow-sm shadow-slate-100 overflow-hidden hidden @[720px]:block">
        <div className="overflow-x-auto">
          <table className="w-full">
            <thead>
              <tr className="border-b border-slate-100">
                <th className="pl-6 pr-4 py-3 text-left text-xs font-semibold text-slate-500 uppercase tracking-wider w-16">
                  Type
                </th>
                <th className="px-3 py-3 text-left text-xs font-semibold text-slate-500 uppercase tracking-wider">
                  Target
                </th>
                <th className="px-3 py-3 text-left text-xs font-semibold text-slate-500 uppercase tracking-wider w-36 @[900px]:w-48">
                  Keychain
                </th>
                <th className="px-3 py-3 w-16 @[900px]:w-20" />
                <th className="pl-3 pr-6 py-3 text-right text-xs font-semibold text-slate-500 uppercase tracking-wider w-36 @[900px]:w-48">
                  Decision
                </th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-50">
              {groups.map((group) => {
                const request = group.representative;
                const row = getRow(request.id);
                const { label: type, isApp } = typeLabel(group);
                const infoExpanded = expandedInfo === request.id;
                const editExpanded = expandedEdit === request.id;

                return (
                  <React.Fragment key={request.id}>
                    <tr className={cx(`transition-colors`, ``)}>
                      <td className="px-4 py-3 align-top">
                        <Badge type={isApp ? `yellow` : `blue`} size="small">
                          {type}
                        </Badge>
                      </td>
                      <td className="px-3 py-3 align-top">
                        <div className="flex flex-col">
                          <div className="flex items-center gap-2">
                            <span className="font-mono text-sm text-slate-900 truncate max-w-[12rem] @[900px]:max-w-xs">
                              {targetLabel(request)}
                            </span>
                            {group.allRequests.length > 1 && (
                              <span className="shrink-0 text-xs text-slate-400 bg-slate-100 rounded-full px-2 py-0.5">
                                {group.allRequests.length}
                              </span>
                            )}
                          </div>
                          {(request.appName || request.requestComment) && (
                            <span className="text-xs text-slate-400 mt-0.5">
                              {request.appName && (
                                <span className="text-violet-400">{request.appName}</span>
                              )}
                              {request.appName && request.requestComment && ` · `}
                              {request.requestComment && (
                                <span className="italic">
                                  &ldquo;{request.requestComment}&rdquo;
                                </span>
                              )}
                            </span>
                          )}
                          <NaughtyWarning group={group} />
                        </div>
                      </td>
                      <td
                        className={cx(
                          `px-3 py-3 transition-opacity`,
                          row.decision === `reject`
                            ? `opacity-0 pointer-events-none`
                            : `opacity-100`,
                        )}
                      >
                        <KeychainSelect
                          keychains={keychains}
                          value={row.keychainId}
                          disabled={false}
                          overridden={row.keychainOverridden}
                          onChange={(keychainId) =>
                            updateRow(request.id, {
                              keychainId,
                              keychainOverridden: keychainId !== globalKeychainId,
                            })
                          }
                        />
                      </td>
                      <td className="px-3 py-3">
                        <div className="flex items-center gap-1">
                          <button
                            onClick={() => {
                              setExpandedInfo(infoExpanded ? null : request.id);
                              if (expandedEdit === request.id) setExpandedEdit(null);
                            }}
                            className={cx(
                              `p-1 rounded-lg transition-colors`,
                              infoExpanded
                                ? `bg-violet-100 text-violet-600`
                                : `text-slate-400 hover:text-violet-500 hover:bg-violet-50`,
                            )}
                          >
                            <InformationCircleIcon className="w-[18px] h-[18px]" />
                          </button>
                          {row.decision !== `reject` && (
                            <button
                              onClick={() => {
                                setExpandedEdit(editExpanded ? null : request.id);
                                if (infoExpanded) setExpandedInfo(null);
                              }}
                              className={cx(
                                `p-1 rounded-lg transition-colors`,
                                editExpanded
                                  ? `bg-violet-100 text-violet-600`
                                  : `text-slate-400 hover:text-violet-500 hover:bg-violet-50`,
                              )}
                            >
                              <AdjustmentsHorizontalIcon className="w-[18px] h-[18px]" />
                            </button>
                          )}
                        </div>
                      </td>
                      <td className="px-3 py-3">
                        <DecisionButtons
                          decision={row.decision}
                          onToggle={(decision) => updateRow(request.id, { decision })}
                        />
                      </td>
                    </tr>
                    {infoExpanded && (
                      <tr className="bg-slate-50">
                        <td colSpan={5} className="px-6 py-4">
                          <InfoPanel request={request} group={group} />
                        </td>
                      </tr>
                    )}
                    {editExpanded && (
                      <tr className="bg-violet-50/30">
                        <td colSpan={5} className="px-6 py-4">
                          <EditPanel
                            keyRecord={group.key}
                            row={row}
                            onUpdate={(update) => updateRow(request.id, update)}
                          />
                        </td>
                      </tr>
                    )}
                  </React.Fragment>
                );
              })}
            </tbody>
          </table>
        </div>
      </div>

      {/* bottom action bar */}
      <div className="sticky bottom-0 mt-3 @[720px]:mt-0 @[720px]:rounded-b-2xl @[720px]:border @[720px]:border-t-0 @[720px]:border-slate-200 bg-slate-50/95 @[720px]:bg-slate-50/50 backdrop-blur-sm @[720px]:backdrop-blur-none rounded-2xl @[720px]:rounded-t-none px-4 py-4 shadow-[0_-8px_24px_rgba(0,0,0,0.12)] @[720px]:shadow-none z-10">
        <div className="flex flex-col sm:flex-row items-stretch sm:items-center justify-between gap-3">
          {groups.length > 1 && (
            <div className="flex items-center gap-2">
              <button
                onClick={() => setAllDecisions(`reject`)}
                className="flex-1 sm:flex-initial inline-flex items-center justify-center px-4 py-2 rounded-xl text-sm font-medium bg-white border border-slate-200 text-slate-600 hover:bg-red-50 hover:text-red-600 hover:border-red-200 transition-colors shadow-sm"
              >
                <XMarkIcon className="w-4 h-4 mr-1.5" />
                Deny all
              </button>
              <button
                onClick={() => setAllDecisions(`accept`)}
                className="flex-1 sm:flex-initial inline-flex items-center justify-center px-4 py-2 rounded-xl text-sm font-medium bg-white border border-slate-200 text-slate-600 hover:bg-green-50 hover:text-green-600 hover:border-green-200 transition-colors shadow-sm"
              >
                <CheckIcon className="w-4 h-4 mr-1.5" />
                Accept all
              </button>
            </div>
          )}
          <div className="flex flex-col sm:flex-row items-stretch sm:items-center gap-3 sm:ml-auto">
            {rejectCount > 0 && (
              <input
                type="text"
                placeholder="Deny comment (optional)..."
                value={denyComment}
                onChange={(e) => setDenyComment(e.target.value)}
                className="border border-slate-200 rounded-xl px-3 py-2 text-sm text-slate-600 placeholder:text-slate-300 focus:outline-none focus:ring-2 focus:ring-violet-500 focus:border-violet-500 sm:w-64"
              />
            )}
            <Button
              type="button"
              onClick={handleSubmit}
              color="primary"
              size="medium"
              disabled={acceptCount + rejectCount === 0 || submitting}
            >
              {submitting ? `Submitting...` : `Submit`}
              {groups.length > 1 && (acceptCount > 0 || rejectCount > 0) && (
                <span className="ml-2 opacity-60 text-xs font-normal">
                  ({acceptCount > 0 ? `${acceptCount} accept` : ``}
                  {acceptCount > 0 && rejectCount > 0 ? `, ` : ``}
                  {rejectCount > 0 ? `${rejectCount} deny` : ``}
                  {undecidedCount > 0
                    ? `${acceptCount + rejectCount > 0 ? `, ` : ``}${undecidedCount} skipped`
                    : ``}
                  )
                </span>
              )}
            </Button>
          </div>
        </div>
      </div>
    </div>
  );
};

const KeychainSelect: React.FC<{
  keychains: KeychainSummary[];
  value: UUID;
  disabled: boolean;
  overridden?: boolean;
  onChange: (id: UUID) => void;
}> = ({ keychains, value, disabled, overridden, onChange }) => (
  <select
    value={value}
    disabled={disabled}
    onChange={(e) => onChange(e.target.value)}
    className={cx(
      `w-full border rounded-xl @[720px]:rounded-lg pl-3 pr-8 py-2.5 @[720px]:py-1.5 text-sm truncate focus:outline-none focus:ring-2 focus:ring-violet-500 focus:border-violet-500`,
      disabled
        ? `bg-slate-50 border-slate-100 text-slate-300 cursor-not-allowed`
        : overridden
          ? `bg-violet-50 border-violet-300 text-violet-700 cursor-pointer`
          : `bg-white border-slate-200 text-slate-700 cursor-pointer`,
    )}
  >
    {keychains.map((kc) => (
      <option key={kc.id} value={kc.id}>
        {kc.name}
      </option>
    ))}
  </select>
);

const DecisionButtons: React.FC<{
  decision: Decision;
  onToggle: (decision: Decision) => void;
  fullWidth?: boolean;
}> = ({ decision, onToggle, fullWidth }) => (
  <div className={cx(`flex items-center justify-end gap-2`, fullWidth && `w-full`)}>
    <button
      onClick={() => onToggle(decision === `reject` ? `undecided` : `reject`)}
      className={cx(
        `inline-flex items-center justify-center px-3 py-2.5 @[720px]:py-1.5 rounded-xl @[720px]:rounded-lg text-sm font-medium transition-all`,
        fullWidth && `flex-1`,
        decision === `reject`
          ? `border border-red-300 text-red-600`
          : `border border-slate-200 bg-white text-slate-400 hover:border-red-200 hover:text-red-500`,
      )}
    >
      <XMarkIcon className="w-4 h-4 mr-1" />
      Deny
    </button>
    <button
      onClick={() => onToggle(decision === `accept` ? `undecided` : `accept`)}
      className={cx(
        `inline-flex items-center justify-center px-3 py-2.5 @[720px]:py-1.5 rounded-xl @[720px]:rounded-lg text-sm font-medium transition-all`,
        fullWidth && `flex-1`,
        decision === `accept`
          ? `border border-green-400 text-green-600`
          : `border border-slate-200 bg-white text-slate-400 hover:border-green-200 hover:text-green-500`,
      )}
    >
      <CheckIcon className="w-4 h-4 mr-1" />
      Accept
    </button>
  </div>
);

const EditPanel: React.FC<{
  keyRecord: RequestGroup[`key`];
  row: RowState;
  onUpdate: (update: Partial<RowState>) => void;
}> = ({ keyRecord, row, onUpdate }) => {
  const showDomain = hasDomainScope(keyRecord);
  return (
    <div
      className={cx(
        `grid gap-4 text-sm`,
        showDomain ? `grid-cols-1 sm:grid-cols-3` : `grid-cols-1 sm:grid-cols-2`,
      )}
    >
      {showDomain && (
        <div className="flex flex-col gap-1.5">
          <label className="text-slate-400 text-xs uppercase tracking-wider font-semibold">
            Domain scope
          </label>
          <div className="flex items-center gap-2">
            <button
              onClick={() => onUpdate({ addressType: `standard` })}
              className={cx(
                `px-3 py-1.5 rounded-lg text-sm font-medium border transition-colors`,
                row.addressType === `standard`
                  ? `border-violet-300 bg-violet-50 text-violet-700`
                  : `border-slate-200 bg-white text-slate-400 hover:border-violet-200 hover:text-violet-500`,
              )}
            >
              Standard
            </button>
            <button
              onClick={() => onUpdate({ addressType: `strict` })}
              className={cx(
                `px-3 py-1.5 rounded-lg text-sm font-medium border transition-colors`,
                row.addressType === `strict`
                  ? `border-violet-300 bg-violet-50 text-violet-700`
                  : `border-slate-200 bg-white text-slate-400 hover:border-violet-200 hover:text-violet-500`,
              )}
            >
              Strict
            </button>
          </div>
          <p className="text-xs text-slate-400 h-4">
            {row.addressType === `standard`
              ? `Unlocks all subdomains`
              : `Exact domain only`}
          </p>
        </div>
      )}
      <div className="flex flex-col gap-1.5">
        <label className="text-slate-400 text-xs uppercase tracking-wider font-semibold">
          Expiration
        </label>
        <input
          type="date"
          value={row.expiration ?? ``}
          onChange={(e) => onUpdate({ expiration: e.target.value || undefined })}
          className="border border-slate-200 rounded-lg px-3 py-1.5 text-sm text-slate-700 focus:outline-none focus:ring-2 focus:ring-violet-500 focus:border-violet-500 w-44"
        />
        <p className="text-xs text-slate-400 h-4">
          {row.expiration ? `Key expires on this date` : `No expiration (permanent)`}
        </p>
      </div>
      <div className="flex flex-col gap-1.5">
        <label className="text-slate-400 text-xs uppercase tracking-wider font-semibold">
          Note
        </label>
        <input
          type="text"
          placeholder="Optional note..."
          value={row.comment ?? ``}
          onChange={(e) => onUpdate({ comment: e.target.value || undefined })}
          className="border border-slate-200 rounded-lg px-3 py-1.5 text-sm text-slate-700 placeholder:text-slate-300 focus:outline-none focus:ring-2 focus:ring-violet-500 focus:border-violet-500"
        />
      </div>
    </div>
  );
};

const NaughtyWarning: React.FC<{ group: RequestGroup }> = ({ group }) => {
  const info = naughtyInfo(group);
  if (!info) return null;
  return (
    <p
      className={cx(
        `text-xs mt-1 mb-2 ml-0.5`,
        info.level === `deny` ? `text-red-400` : `text-amber-500`,
      )}
    >
      {info.level === `deny` ? (
        `⚠ `
      ) : (
        <InformationCircleIcon className="w-3.5 h-3.5 inline -mt-px mr-0.5" />
      )}
      {info.reason}
    </p>
  );
};

const InfoPanel: React.FC<{ request: UnlockRequest; group: RequestGroup }> = ({
  request,
  group,
}) => {
  const items: Array<{ label: string; value: React.ReactNode; wide?: boolean }> = [];
  if (group.allRequests.length > 1) {
    const allComments = group.allRequests
      .map((r) => r.requestComment)
      .filter((c): c is string => !!c);
    const allUrls = group.allRequests.map((r) => r.url).filter((u): u is string => !!u);
    const uniqueUrls = [...new Set(allUrls)];
    if (uniqueUrls.length > 0) {
      items.push({
        label: `Requested URLs (${uniqueUrls.length})`,
        value: (
          <ul className="space-y-1">
            {uniqueUrls.map((url) => (
              <li key={url}>
                <a
                  href={url}
                  target="_blank"
                  rel="noopener noreferrer"
                  className="font-mono text-xs break-all text-violet-600 hover:text-violet-800 underline decoration-violet-300"
                >
                  {url.replace(/^https?:\/\//, ``)}
                </a>
              </li>
            ))}
          </ul>
        ),
        wide: true,
      });
    }
    if (allComments.length > 0) {
      const uniqueComments = [...new Set(allComments)];
      items.push({
        label: `Comments (${uniqueComments.length})`,
        value: (
          <ul className="space-y-1">
            {uniqueComments.map((c) => (
              <li key={c} className="italic text-slate-600">
                &ldquo;{c}&rdquo;
              </li>
            ))}
          </ul>
        ),
        wide: true,
      });
    }
  } else {
    if (request.requestComment) {
      items.push({
        label: `Comment`,
        value: (
          <span className="italic text-slate-600">
            &ldquo;{request.requestComment}&rdquo;
          </span>
        ),
        wide: true,
      });
    }
    if (request.url) {
      items.push({
        label: `Full URL`,
        value: (
          <a
            href={request.url}
            target="_blank"
            rel="noopener noreferrer"
            className="font-mono text-xs break-all text-violet-600 hover:text-violet-800 underline decoration-violet-300"
          >
            {request.url}
          </a>
        ),
        wide: true,
      });
    }
  }
  if (request.domain) {
    items.push({
      label: `Domain`,
      value: (
        <a
          href={`https://${request.domain}`}
          target="_blank"
          rel="noopener noreferrer"
          className="font-mono text-xs text-violet-600 hover:text-violet-800 underline decoration-violet-300"
        >
          {request.domain}
        </a>
      ),
    });
  }
  if (request.appName) {
    items.push({ label: `App`, value: request.appName });
  }
  if (request.appBundleId) {
    items.push({
      label: `Bundle ID`,
      value: <span className="font-mono text-xs break-all">{request.appBundleId}</span>,
    });
  }
  if (request.appCategories.length > 0) {
    items.push({ label: `Categories`, value: request.appCategories.join(`, `) });
  }
  if (request.ipAddress) {
    items.push({
      label: `IP Address`,
      value: <span className="font-mono text-xs">{request.ipAddress}</span>,
    });
  }
  return (
    <div className="grid grid-cols-1 sm:grid-cols-2 @[720px]:grid-cols-3 gap-4 text-sm">
      {items.map((item) => (
        <div key={item.label} className={item.wide ? `col-span-full` : undefined}>
          <label className="text-slate-400 text-xs uppercase tracking-wider font-semibold">
            {item.label}
          </label>
          <div className="text-slate-700 mt-1">{item.value}</div>
        </div>
      ))}
    </div>
  );
};

export default BatchUnlockRequests;
