type Article = {
  type: 'engineering' | 'parental-controls';
  title: string;
  slug: string;
};

const articles: Article[] = [
  {
    type: `parental-controls`,
    title: `How to lock down an iPhone`,
    slug: `definitive-guide-to-locking-down-an-iphone`,
  },
  {
    type: `parental-controls`,
    title: `What You Forgot Locking Down Your Kids’ iPhone`,
    slug: `five-things-you-forgot-when-locking-down-your-kids-iphone`,
  },
  {
    type: `parental-controls`,
    title: `Mac internet filtering/blocking`,
    slug: `mac-internet-filter`,
  },
  {
    type: `parental-controls`,
    title: `Gertrude for mac keylogging`,
    slug: `mac-keylogger`,
  },
  {
    type: `parental-controls`,
    title: `No Removing Images GIF search in iOS 17`,
    slug: `ios-17-cant-delete-messages-images`,
  },
  {
    type: `parental-controls`,
    title: `Guía Definitiva para Bloquear un iPhone`,
    slug: `guia-definitiva-para-bloquear-un-iphone`,
  },
  {
    type: `engineering`,
    title: `Generic TypeScript React Components`,
    slug: `generic-react-components-typescript`,
  },
  {
    type: `engineering`,
    title: `Protocol Static Function Quirk`,
    slug: `swift-protocol-static-function-selection-quirk`,
  },
  {
    type: `engineering`,
    title: `Vapor + Postgres + GH Actions`,
    slug: `vapor-swift-postgres-github-action-test-workflow`,
  },
  {
    type: `engineering`,
    title: `Query Running MacOS Apps`,
    slug: `querying-running-applications-in-macos`,
  },
  {
    type: `engineering`,
    title: `Requesting Accesibility Control`,
    slug: `macos-request-accessibility-control`,
  },
  {
    type: `engineering`,
    title: `... View all posts [6]`,
    slug: `TODO`,
  },
];

export default articles;
