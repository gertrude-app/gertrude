import React, { useState, useCallback, useEffect } from 'react';
import cx from 'classnames';
import { domain, validate } from '@dash/keys';
import { notNullish } from '@shared/ts-utils';

interface Props {
  type: 'strict' | 'standard' | 'ip' | 'domainRegex';
  unsanitizedAddress: string;
}

const AddressTypeHint: React.FC<Props> = ({ unsanitizedAddress, type }) => {
  const address = domain.sanitizeUserInput(unsanitizedAddress);
  if (domain.isIpAddress(address) && type !== `ip`) {
    return (
      <div data-test="incorrect-ip-hint" className="mt-4 text-right text-red-700">
        Looks like you've entered an IP address. Enable <b>Advanced</b> mode and set the
        {` `}
        <b>Address type</b> above to <b className="whitespace-nowrap">IP address</b>
        {` `}
        if that was your intention.
      </div>
    );
  }

  if (![`strict`, `standard`].includes(type)) {
    return null;
  }

  if (!validate.address(address, type)) {
    return (
      <div
        data-test="invalid-domain-hint"
        className={cx(
          `mt-4 min-h-[47px] text-right text-slate-400 flex justify-end items-center`,
          address.trim() === `` && `opacity-0`,
        )}
      >
        <i className="fas opacity-60 fa-exclamation-triangle mr-2" />
        invalid address
      </div>
    );
  }

  const registrable = domain.registrable(address);
  const subdomain = domain.subdomain(address);
  const hostname = domain.hostname(address) ?? address;
  return (
    <div className="flex justify-end">
      {type === `standard` && (
        <div className="text-right text-sm text-slate-400 mb-2 mt-3 overflow-hidden">
          <div className="mb-1">
            Allows all subdomains of{` `}
            <Address testId="standard-registrable">{registrable}</Address>
            &mdash; for example:
          </div>
          <RotatingSubdomain
            domain={registrable ?? address}
            blocked={false}
            subdomains={[subdomain, `www`, `images`, `cdn`, `static`, `api`].filter(
              notNullish,
            )}
          />
        </div>
      )}
      {type === `strict` && (
        <div className="text-right text-sm text-slate-400 mb-2 mt-3 overflow-hidden">
          <div className="mb-1">
            Only allows access to{` `}
            {subdomain || (registrable ?? address).length > 35 ? (
              <Address testId="strict-hostname">{hostname}</Address>
            ) : (
              <>
                <Address testId="strict-apex">{registrable ?? address}</Address> and{` `}
                <Address testId="strict-www">www.{registrable ?? address}</Address>
              </>
            )}
            &mdash; subdomains such as these are blocked:
          </div>
          <RotatingSubdomain
            domain={registrable ?? address}
            subdomains={[`images`, `cdn`, `static`, `api`, `docs`]}
            blocked
          />
        </div>
      )}
    </div>
  );
};

export default AddressTypeHint;

interface RotatingSubdomainProps {
  domain: string;
  subdomains: string[];
  blocked?: boolean;
}

const RotatingSubdomain: React.FC<RotatingSubdomainProps> = ({
  domain,
  subdomains,
  blocked,
}) => {
  const [curIndex, setCurIndex] = useState(0);

  const shift = useCallback(() => {
    if (curIndex === subdomains.length - 1) {
      setCurIndex(0);
    } else {
      setCurIndex(curIndex + 1);
    }
  }, [curIndex, subdomains.length]);

  useEffect(() => {
    const id = setTimeout(shift, 2000);
    return () => {
      clearTimeout(id);
    };
  }, [curIndex, shift]);

  return (
    <Address>
      <span
        data-test="rotating-subdomains"
        data-test-rotating-subdomains={subdomains.join(`,`)}
        className="relative [transition:200ms] overflow-hidden whitespace-nowrap ml-12"
      >
        {subdomains.filter(notNullish).map((subdomain, index) => (
          <span
            key={subdomain}
            className={cx(
              `absolute right-0 [transition:200ms] opacity-0`,
              index < curIndex && `-top-5`,
              index === curIndex && `-top-0.5 opacity-100`,
              index > curIndex && `top-5`,
              blocked === undefined ? `` : blocked ? `text-red-600` : `text-green-600`,
            )}
          >
            {subdomain}
          </span>
        ))}
      </span>
      {subdomains[curIndex] && `.`}
      {domain}
    </Address>
  );
};

const Address: React.FC<{ children: React.ReactNode; testId?: string }> = ({
  children,
  testId,
}) => (
  <span data-test={testId} className="font-mono text-slate-500 px-1 break-all">
    {children}
  </span>
);
