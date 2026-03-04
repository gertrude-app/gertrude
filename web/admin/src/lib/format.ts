export function formatDate(dateString: string): string {
  const date = new Date(dateString);
  return date.toLocaleDateString(`en-US`, {
    year: `numeric`,
    month: `short`,
    day: `numeric`,
  });
}

export function formatDateTime(dateString: string): string {
  const date = new Date(dateString);
  return date.toLocaleString(`en-US`, {
    month: `short`,
    day: `numeric`,
    hour: `numeric`,
    minute: `2-digit`,
    hour12: true,
  });
}

export function formatTime(dateString: string): string {
  const date = new Date(dateString);
  return date.toLocaleTimeString(`en-US`, {
    hour: `2-digit`,
    minute: `2-digit`,
    second: `2-digit`,
    hour12: false,
  });
}

export function formatElapsed(seconds: number): string {
  if (seconds < 60) {
    return `+${seconds}s`;
  } else if (seconds < 3600) {
    const mins = Math.floor(seconds / 60);
    const secs = seconds % 60;
    return secs > 0 ? `+${mins}m ${secs}s` : `+${mins}m`;
  } else if (seconds < 86400) {
    const hours = Math.floor(seconds / 3600);
    const mins = Math.floor((seconds % 3600) / 60);
    return mins > 0 ? `+${hours}h ${mins}m` : `+${hours}h`;
  } else {
    const days = Math.floor(seconds / 86400);
    const hours = Math.floor((seconds % 86400) / 3600);
    return hours > 0 ? `+${days}d ${hours}h` : `+${days}d`;
  }
}

export function timeAgo(dateString: string): string {
  const seconds = Math.floor((Date.now() - new Date(dateString).getTime()) / 1000);
  if (seconds < 60) return `just now`;
  if (seconds < 3600) return `${Math.floor(seconds / 60)}m ago`;
  if (seconds < 86400) return `${Math.floor(seconds / 3600)}h ago`;
  const days = Math.floor(seconds / 86400);
  return days === 1 ? `1 day ago` : `${days} days ago`;
}

export function unCamelCase(str: string): string {
  return str
    .replace(/([a-z])([A-Z])/g, `$1 $2`)
    .replace(/([A-Z]+)([A-Z][a-z])/g, `$1 $2`)
    .toLowerCase()
    .replace(/^\w/, (c) => c.toUpperCase());
}

export interface TimelineEvent {
  id: string;
  eventId: string;
  label: string;
  detail?: string;
  createdAt: string;
  elapsedSeconds?: number;
}

export function groupEventsByDate<T extends { createdAt: string }>(
  events: T[],
): Map<string, T[]> {
  const groups = new Map<string, T[]>();
  for (const event of events) {
    const dateKey = new Date(event.createdAt).toDateString();
    const existing = groups.get(dateKey) ?? [];
    existing.push(event);
    groups.set(dateKey, existing);
  }
  return groups;
}
