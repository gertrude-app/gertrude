'use client';

import React, { useEffect } from 'react';
import '../styles/globals.css';

const RootLayout: React.FC<{ children: React.FC }> = ({ children }) => {
  useEffect(storeGoogleClickId, []);

  return <>{children}</>;
};

export default RootLayout;

function storeGoogleClickId(): void {
  const match = RegExp(`[?&]gclid=([^&]*)`).exec(window.location.search);
  if (!match || !match[1]) {
    return;
  }
  const gclid = match[1].replace(/\+/g, ` `);
  const date = new Date();
  date.setTime(date.getTime() + 90 * 24 * 60 * 60 * 1000); // 90 days
  const domain = window.location.hostname;
  document.cookie = `gclid=${gclid}; expires=${date.toUTCString()}; path=/; domain=${domain}`;
}
