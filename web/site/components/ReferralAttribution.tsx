'use client';

import { useEffect } from 'react';
import type React from 'react';
import { PARENTS_APP_URL } from '@/lib/urls';

const COOKIE_NAME = `referral_code`;
const SESSION_KEY = `referral_code`;
const COOKIE_TTL_MS = 90 * 24 * 60 * 60 * 1000;

const ReferralAttribution: React.FC = () => {
  useEffect(() => {
    const queryCode = normalizeReferralCode(
      new URL(window.location.href).searchParams.get(`ref`),
    );
    const referralCode = queryCode ?? storedReferralCode();
    if (!referralCode) {
      return;
    }

    if (queryCode) {
      storeReferralCode(queryCode);
    }

    updateSignupLinks(referralCode);
    const observer = new MutationObserver(() => updateSignupLinks(referralCode));
    observer.observe(document.body, { childList: true, subtree: true });
    return () => observer.disconnect();
  }, []);

  return null;
};

export default ReferralAttribution;

function normalizeReferralCode(value: string | null): string | undefined {
  const normalized = value?.trim().toUpperCase();
  return normalized || undefined;
}

function storedReferralCode(): string | undefined {
  try {
    return normalizeReferralCode(sessionStorage.getItem(SESSION_KEY));
  } catch {
    return undefined;
  }
}

function storeReferralCode(referralCode: string): void {
  try {
    sessionStorage.setItem(SESSION_KEY, referralCode);
  } catch {
    return storeReferralCookie(referralCode);
  }

  storeReferralCookie(referralCode);
}

function storeReferralCookie(referralCode: string): void {
  const expires = new Date(Date.now() + COOKIE_TTL_MS).toUTCString();
  const hostname = window.location.hostname;
  const isGertrudeDomain =
    hostname === `gertrude.app` || hostname.endsWith(`.gertrude.app`);
  const domain = isGertrudeDomain ? `; domain=.gertrude.app; Secure` : ``;
  document.cookie = `${COOKIE_NAME}=${referralCode}; expires=${expires}; path=/; SameSite=Lax${domain}`;
}

function updateSignupLinks(referralCode: string): void {
  const parentsUrl = new URL(PARENTS_APP_URL);
  document.querySelectorAll<HTMLAnchorElement>(`a[href]`).forEach((link) => {
    const url = new URL(link.href);
    if (url.origin !== parentsUrl.origin || url.pathname !== `/signup`) {
      return;
    }
    if (url.searchParams.get(`ref`) === referralCode) {
      return;
    }
    url.searchParams.set(`ref`, referralCode);
    link.href = url.toString();
  });
}
