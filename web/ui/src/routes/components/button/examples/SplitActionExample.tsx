import Button from '#/components/ui/Button';
import {
  ArchiveIcon,
  CheckIcon,
  ClockIcon,
  CopyIcon,
  DownloadIcon,
  EyeIcon,
  FileTextIcon,
  SendIcon,
  Trash2Icon,
} from 'lucide-react';
import React from 'react';

type ButtonSize = 'small' | 'medium' | 'large';

const sizes: ButtonSize[] = ['small', 'medium', 'large'];

const SplitActionExample: React.FC = () => {
  return (
    <div className="grid h-full place-items-center p-8">
      <div className="grid w-full max-w-4xl gap-5">
        {sizes.map((size, index) => (
          <div key={size} className="grid items-center gap-3 sm:grid-cols-[5rem_1fr]">
            <div className="font-mono text-xs text-stone-500">{size}</div>
            <div className="flex flex-wrap items-center gap-3">
              <Button
                type="button"
                variant="primary"
                size={size}
                icon={CheckIcon}
                onClick={() => undefined}
                dropdownAriaLabel="Grant with another duration"
                dropdownItems={[
                  { title: 'Grant 5 minutes', icon: ClockIcon, onSelect: () => undefined },
                  ...(index > 0
                    ? [
                        {
                          title: 'Grant 30 minutes',
                          icon: ClockIcon,
                          onSelect: () => undefined,
                        },
                        { title: 'Grant 1 hour', icon: ClockIcon, onSelect: () => undefined },
                      ]
                    : []),
                  ...(index > 1
                    ? [
                        { title: 'Grant 2 hours', icon: ClockIcon, onSelect: () => undefined },
                        {
                          title: 'Custom duration…',
                          icon: ClockIcon,
                          onSelect: () => undefined,
                        },
                      ]
                    : []),
                ]}
              >
                Grant 15 min
              </Button>
              <Button
                type="button"
                variant="default"
                size={size}
                icon={DownloadIcon}
                onClick={() => undefined}
                dropdownItems={[
                  { title: 'Download PDF', icon: FileTextIcon, onSelect: () => undefined },
                  { title: 'Copy link', icon: CopyIcon, onSelect: () => undefined },
                  { title: 'Preview', icon: EyeIcon, onSelect: () => undefined },
                ]}
              >
                Download
              </Button>
              <Button
                type="button"
                variant="destructive"
                size={size}
                icon={Trash2Icon}
                onClick={() => undefined}
                dropdownItems={[
                  { title: 'Archive instead', icon: ArchiveIcon, onSelect: () => undefined },
                  { title: 'Send warning', icon: SendIcon, onSelect: () => undefined },
                ]}
              >
                Delete
              </Button>
            </div>
          </div>
        ))}
      </div>
    </div>
  );
};

export default SplitActionExample;
