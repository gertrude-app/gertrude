import { useSyncExternalStore } from 'react';

let stale = false;
const listeners = new Set<() => void>();

export function markDashboardStale(): void {
  if (stale) return;
  stale = true;
  for (const listener of listeners) {
    listener();
  }
}

export function useDashboardStale(): boolean {
  return useSyncExternalStore(subscribe, snapshot, snapshot);
}

function subscribe(listener: () => void): () => void {
  listeners.add(listener);
  return () => listeners.delete(listener);
}

function snapshot(): boolean {
  return stale;
}
