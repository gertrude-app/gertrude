import { useState, useCallback, useEffect } from 'react';
import cx from 'classnames';

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
  return (
    <div className="flex justify-end">
      {addressType === `standard` && (
        <p className="text-right max-w-lg text-sm text-gray-400 my-2">
          Allows any subdomain of{` `}
          <DemoURL domain={address} subdomains={[``]} />, for example
          {` `}
          <DemoURL
            domain={address}
            rotate
            subdomains={[`images`, `cdn`, `static`, `api`, `docs`]}
            blocked={false}
          />
        </p>
      )}
      {addressType === `strict` && (
        <p className="text-right max-w-lg text-sm text-gray-400 my-2">
          Only allows access to{` `}
          <DemoURL blocked={false} domain={address} subdomains={[`www`]} />. Subdomains
          like
          {` `}
          <DemoURL
            domain={address}
            rotate
            subdomains={[`images`, `cdn`, `static`, `api`, `docs`]}
            blocked
          />
          {` `}
          are blocked
        </p>
      )}
    </div>
  );
};

export default SubdomainDemo;

interface RotatingSubdomainProps {
  domain: string;
  rotate?: boolean;
  subdomains: string[];
  blocked?: boolean;
}

const DemoURL: React.FC<RotatingSubdomainProps> = ({
  domain,
  rotate = false,
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
    const id = setTimeout(shift, 2500);
    return () => {
      clearTimeout(id);
    };
  }, [curIndex, shift]);

  return (
    <span className="font-mono text-gray-500 px-1 rounded">
      <span
        className={cx(
          `relative [transition:200ms] overflow-hidden whitespace-nowrap`,
          rotate && `ml-12`,
        )}
      >
        {rotate
          ? subdomains.map((subdomain, index) => (
              <span
                key={subdomain}
                className={cx(
                  `absolute right-0 [transition:200ms] opacity-0`,
                  index < curIndex && `-top-5`,
                  index === curIndex && `-top-0.5 opacity-100`,
                  index > curIndex && `top-5`,
                  blocked === undefined
                    ? ``
                    : blocked
                    ? `text-red-600`
                    : `text-green-600`,
                )}
              >
                {subdomain}
              </span>
            ))
          : subdomains[curIndex]}
      </span>
      {subdomains[curIndex] && `.`}
      {domain}
    </span>
  );
};
