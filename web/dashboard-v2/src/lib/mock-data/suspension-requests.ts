export type SuspensionRequest = {
  personName: string;
  duration: string; // '1 hour', '45 minutes', etc.
  reason?: string; // 'Need to turn in my assignment', 'YouTube video for school', etc.
};

export const mockSuspensionRequests: SuspensionRequest[] = [
  {
    personName: `Sally`,
    duration: `15 minutes`,
    reason: `I need to check the group chat about tomorrow's carpool.`,
  },
  {
    personName: `Jimmy`,
    duration: `2 hours`,
  },
  {
    personName: `Maggie`,
    duration: `1 hour`,
    reason: `Can I play Minecraft with cousins after chores?`,
  },
  {
    personName: `Jimmy`,
    duration: `30 minutes`,
    reason: `Need to submit my science worksheet and upload the photos.`,
  },
  {
    personName: `Theo`,
    duration: `45 minutes`,
    reason: `Watching the volcano video for homework.`,
  },
];
