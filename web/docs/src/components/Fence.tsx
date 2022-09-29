import React, { Fragment } from 'react';
import Highlight, { defaultProps } from 'prism-react-renderer';

interface Props {
  children: string;
  language: any;
}

const Fence: React.FC<Props> = ({ children, language }) => (
  <Highlight
    {...defaultProps}
    code={children.trimEnd()}
    language={language}
    theme={undefined}
  >
    {({ className, style, tokens, getTokenProps }) => (
      <pre className={className} style={style}>
        <code>
          {tokens.map((line, lineIndex) => (
            <Fragment key={lineIndex}>
              {line
                .filter((token) => !token.empty)
                .map((token, tokenIndex) => (
                  <span key={tokenIndex} {...getTokenProps({ token })} />
                ))}
              {`\n`}
            </Fragment>
          ))}
        </code>
      </pre>
    )}
  </Highlight>
);

export default Fence;
