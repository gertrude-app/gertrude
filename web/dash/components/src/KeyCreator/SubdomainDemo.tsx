import React, { useState, useCallback, useEffect } from 'react';
import cx from 'classnames';
import { domain } from '@dash/keys';
import { notNullish } from '@shared/ts-utils';

interface Props {
  address: string;
  addressType: 'strict' | 'standard' | 'ip' | 'domainRegex';
}

const SubdomainDemo: React.FC<Props> = ({ address, addressType }) => {
  if (
    (addressType !== `strict` && addressType !== `standard`) ||
    !address.includes(`.`)
  ) {
    return null;
  }

  const registrable = domain.registrable(address);
  const subdomain = domain.subdomain(address);
  const hostname = domain.hostname(address) ?? address;
  return (
    <div className="flex justify-end">
      {addressType === `standard` && (
        <div className="text-right text-sm text-gray-400 mb-2 mt-3 overflow-hidden">
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
      {addressType === `strict` && (
        <div className="text-right text-sm text-gray-400 mb-2 mt-3 overflow-hidden">
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

export default SubdomainDemo;

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
  <span data-test={testId} className="font-mono text-gray-500 px-1 break-all">
    {children}
  </span>
);
