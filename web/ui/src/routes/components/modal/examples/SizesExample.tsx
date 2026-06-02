import React from 'react';
import Button from '#/components/ui/Button';
import Modal from '#/components/ui/Modal';

type ModalSize = 'small' | 'medium' | 'large';

const modalSizes: ModalSize[] = ['small', 'medium', 'large'];

const SizesExample: React.FC = () => {
  const [openSize, setOpenSize] = React.useState<ModalSize | null>(null);

  return (
    <div className="grid h-full place-items-center p-8">
      <div className="flex flex-wrap justify-center gap-3">
        {modalSizes.map((size) => (
          <Button key={size} type="button" onClick={() => setOpenSize(size)}>
            Open {size}
          </Button>
        ))}
      </div>
      {modalSizes.map((size) => (
        <Modal
          key={size}
          open={openSize === size}
          onOpenChange={(open) => setOpenSize(open ? size : null)}
          size={size}
          title={`${size[0].toUpperCase()}${size.slice(1)} modal`}
          description="The same component switches from dialog to drawer automatically on narrow screens."
          footer={
            <Button type="button" variant="primary" onClick={() => setOpenSize(null)}>
              Done
            </Button>
          }
        >
          <div className="grid gap-3 text-sm leading-6 text-stone-600">
            <p>
              This example uses the {size} size. Larger sizes give complex forms and
              review flows more horizontal room on desktop.
            </p>
            <p>
              On mobile, size does not affect the drawer width because the sheet fills the
              screen horizontally.
            </p>
          </div>
        </Modal>
      ))}
    </div>
  );
};

export default SizesExample;
