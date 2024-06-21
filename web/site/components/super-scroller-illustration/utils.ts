export type Step =
  | '1-0_start'
  | '1-1_openLoginScreen'
  | '1-2_logIn'
  | '2-0_start'
  | '2-1_openMac'
  | '2-2_clickDownloadButton'
  | '3-0_start'
  | '4-0_start'
  | '4-1_clickUnlockRequest'
  | '5-0_start'
  | '5-1_clickNotification'
  | '5-2_clickAcceptRequest'
  | '6-0_start';

export function parseStep(stepInQuestion: Step): [number, number] | null {
  const numberPart = stepInQuestion.split(`_`)[0];
  if (!numberPart) return null;
  const [stepNum, subStepNum] = numberPart.split(`-`).map(Number);
  if (
    stepNum === undefined ||
    subStepNum === undefined ||
    isNaN(stepNum) ||
    isNaN(subStepNum)
  )
    return null;
  return [stepNum, subStepNum];
}

export function compareTo(comparison: Step): (stepInQuestion: Step) => boolean {
  return (stepInQuestion: Step) => {
    const [stepNum, subStepNum] = parseStep(stepInQuestion) ?? ([false, false] as const);
    const [currentStepNum, currentSubStepNum] =
      parseStep(comparison) ?? ([false, false] as const);
    if (stepNum === false || currentStepNum === false) return false;
    if (stepNum > currentStepNum) return false;
    if (stepNum === currentStepNum && subStepNum > currentSubStepNum) return false;
    return true;
  };
}

export function initializeStep(num: number): Step {
  switch (num) {
    case 1:
      return `1-0_start`;
    case 2:
      return `2-0_start`;
    case 3:
      return `3-0_start`;
    case 4:
      return `4-0_start`;
    case 5:
      return `5-0_start`;
    case 6:
      return `6-0_start`;
    default:
      return `1-0_start`;
  }
}
