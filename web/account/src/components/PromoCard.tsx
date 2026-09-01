import { Text, VStack } from '@gertrude/ui';
import cx from 'clsx';
import React from 'react';

type Props = {
  primaryText: React.ReactNode;
  secondaryText: React.ReactNode;
  className?: string;
  flush?: boolean;
};

const PromoCard: React.FC<Props> = ({
  primaryText,
  secondaryText,
  className,
  flush = false,
}) => (
  <div
    className={cx(
      flush
        ? `rounded-none`
        : `rounded-xl bg-gradient-to-b from-stone-200 to-violet-300 p-px`,
      className,
    )}
  >
    <div
      className={cx(
        `relative overflow-hidden bg-white px-6 py-8`,
        flush ? `rounded-none` : `rounded-[11px]`,
      )}
    >
      <img
        src="/promo/grainy-gradient.webp"
        alt=""
        width={1000}
        height={1000}
        decoding="async"
        className="pointer-events-none absolute inset-0 size-full object-fill opacity-20"
      />
      <div
        aria-hidden
        className="pointer-events-none absolute inset-0 bg-[url('/dot-noise-pattern.svg')] bg-[length:720px_720px] bg-repeat"
        style={{
          WebkitMaskImage: `linear-gradient(to bottom, transparent, black)`,
          maskImage: `linear-gradient(to bottom, transparent, black)`,
        }}
      />
      <VStack gap={2} className="relative min-w-0 text-center">
        <div className="relative mx-auto mb-3 grid size-8 place-items-center">
          <div
            aria-hidden
            className="absolute -inset-x-32 -inset-y-20 z-0 translate-y-5 rounded-full bg-[radial-gradient(ellipse,rgba(255,255,255,0.95)_0%,rgba(255,255,255,0.7)_38%,rgba(255,255,255,0)_72%)] blur-sm"
          />
          <img
            src="/promo/logo-stone.svg"
            alt=""
            width={365}
            height={365}
            className="relative z-10 size-8 opacity-70"
          />
        </div>
        <Text variant="bodyLargeStrong" className="relative z-10">
          {primaryText}
        </Text>
        <Text
          variant="proseSubtle"
          className="relative z-10 bg-gradient-to-r from-violet-950/85 to-fuchsia-950/85 bg-clip-text text-transparent"
        >
          {secondaryText}
        </Text>
      </VStack>
    </div>
  </div>
);

export default PromoCard;
