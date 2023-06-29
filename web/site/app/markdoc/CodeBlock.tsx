import React, { useEffect, useRef } from 'react';
import Prism from 'prismjs';

import 'prismjs/themes/prism-tomorrow.min.css';
import 'prismjs/components/prism-rust.min';
import 'prismjs/components/prism-swift.min';
import 'prismjs/components/prism-yaml.min';
import 'prismjs/components/prism-typescript.min';

const CodeBlock: React.FC<{ children: React.ReactNode; 'data-language': string }> = ({
  children,
  'data-language': language,
}) => {
  const ref = useRef<HTMLPreElement>(null);

  useEffect(() => {
    if (ref.current) Prism.highlightElement(ref.current, false);
  }, [children]);

  return (
    <div className="code" aria-live="polite">
      <pre ref={ref} className={`language-${language}`}>
        {children}
      </pre>
    </div>
  );
};

export default CodeBlock;
