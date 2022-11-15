type Size = 'xs' | 'sm' | 'md' | 'lg' | 'xl';

export const SIZES = {
  xs: { width: 375, height: 812 },
  sm: { width: 640, height: 768 },
  md: { width: 768, height: 720 },
  lg: { width: 1024, height: 768 },
  xl: { width: 1280, height: 900 },
} as const;

export interface ScreenshotTest {
  name: string;
  url: string;
  sizes: Array<{ width: number; height: number }>;
}

export interface StoryData {
  id: string;
  name: string;
  title: string;
  importPath: string;
}

function isSize(value: string): value is Size {
  return Object.keys(SIZES).includes(value);
}

export function extractScreenshotTest(
  fileContent: string,
  storyData: Omit<StoryData, 'importPath'>,
): ScreenshotTest | null {
  const namedExport = storyData.name.replace(/\s/g, ``);
  if (!fileContent.includes(namedExport)) {
    return null;
  }

  const matches = fileContent.matchAll(/@screenshot:?\s*([^\s]*)\nexport const (\w+)/gm);
  for (const match of matches) {
    const [, sizeStr = ``, name = ``] = match;
    if (name !== namedExport) {
      continue;
    }
    return {
      name: storyData.id,
      url: `http://localhost:4777/iframe.html?args=&id=${storyData.id}&viewMode=story`,
      sizes: parseTestSizes(sizeStr),
    };
  }

  return null;
}

export function parseTestSizes(sizeStr?: string): ScreenshotTest['sizes'] {
  if (!sizeStr) {
    return [SIZES.xs];
  }

  const sizes: ScreenshotTest['sizes'] = [];
  const parts = sizeStr.split(`,`);
  for (const part of parts) {
    if (isSize(part)) {
      sizes.push(SIZES[part]);
    } else if (part.includes(`/`)) {
      const [width = ``, height = ``] = part.split(`/`);
      sizes.push({
        width: isSize(width) ? SIZES[width].width : parseInt(width, 10),
        height: isSize(height) ? SIZES[height].height : parseInt(height, 10),
      });
    } else {
      throw new Error(`Invalid size: ${part}`);
    }
  }

  return sizes;
}
