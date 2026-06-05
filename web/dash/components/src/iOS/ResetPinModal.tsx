import { posessive } from '@shared/string';
import React from 'react';
import CodeChip from '../CodeChip';
import Modal from '../Modal/Modal';

const ResetPinModal: React.FC<{
  isOpen: boolean;
  onClose: () => void;
  childName: string;
  deviceType: string;
  code: number;
}> = ({ isOpen, onClose, childName, deviceType, code }) => (
  <Modal
    isOpen={isOpen}
    icon="key"
    title={`Reset PIN for ${posessive(childName)} ${deviceType}`}
    onDismiss={onClose}
    primaryButton={onClose}
  >
    <div className="space-y-3 mb-2 flex flex-col">
      <div>
        On the {deviceType}, open <b>Gertrude AM &rarr; Settings &rarr; Forgot PIN</b>,
        then enter the code below:
      </div>
      <CodeChip code={code} />
      <div className="text-slate-400">This code expires in one hour.</div>
    </div>
  </Modal>
);

export default ResetPinModal;
