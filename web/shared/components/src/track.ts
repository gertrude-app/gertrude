export function trackEvent(id: string, data: Record<string, unknown> = {}): void {
  try {
    // @ts-ignore
    if (`gtag` in window && typeof window.gtag === `function`) {
      // @ts-ignore
      window.gtag(`event`, id, data);
    }
  } catch {
    // ¯\_(ツ)_/¯
  }
}

export function trackNavigation(id: string, url: string): void {
  try {
    // @ts-ignore
    if (`gtag` in window && typeof window.gtag === `function`) {
      const timeout = setTimeout(() => (window.location.href = url), 2000);
      // @ts-ignore
      window.gtag(`event`, id, {
        // google will call this after the event is received
        event_callback: () => {
          clearTimeout(timeout);
          window.location.href = url;
        },
        event_timeout: 1000,
      });
    } else {
      window.location.href = url;
    }
  } catch {
    window.location.href = url;
  }
}
