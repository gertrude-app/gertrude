export type UnlockRequest = {
  id: string;
  domains: string[];
  personName: string;
  reason?: string;
};

export const mockUnlockRequests: UnlockRequest[] = [
  {
    personName: `Maggie`,
    domains: [
      `minecraft.net`,
      `www.minecraft.net`,
      `launcher.mojang.com`,
      `resources.download.minecraft.net`,
      `libraries.minecraft.net`,
      `piston-meta.mojang.com`,
      `sessionserver.mojang.com`,
      `authserver.mojang.com`,
    ],
    reason: `Installing the update before playing with cousins.`,
    id: `1`,
  },
  {
    personName: `Jimmy`,
    domains: [`scratch.mit.edu`],
    id: `2`,
  },
  {
    personName: `Sally`,
    domains: [`docs.google.com`],
    reason: `Working on the history slideshow with my group.`,
    id: `3`,
  },
  {
    personName: `Jimmy`,
    domains: [`khanacademy.org`, `cdn.kastatic.org`],
    reason: `Need the practice problems and videos for math homework.`,
    id: `4`,
  },
  {
    personName: `Theo`,
    domains: [`youtube.com`, `youtu.be`],
    reason: `Watching the volcano experiment video for school.`,
    id: `5`,
  },
];
