import { CreateSignedScreenshotUpload } from './gertie-scratch';

export async function foo(input: CreateSignedScreenshotUpload.Input): Promise<any> {
  const foo = CreateSignedScreenshotUpload.send([`lol`]);
  return foo;
}
