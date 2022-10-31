const MainFooter: React.FC = () => {
  return (
    <footer className="p-7 flex flex-col md:flex-row md:px-16 lg:px-24 md:justify-between justify-center items-center bg-fuchsia-500">
      <p className="text-white text-opacity-50 text-xl">
        © {new Date().getFullYear()} NetRivet Inc.
      </p>
      <ul className="flex flex-col md:flex-row space-y-1 md:space-y-0 md:space-x-6 w-full md:w-auto items-center text-white/50 mt-6 md:mt-0 mb-3 md:mb-0">
        <li>
          <a href="/contact">Contact us</a>
        </li>
        <li>
          <a href="https://docs.gertrude.app">Documentation</a>
        </li>
      </ul>
    </footer>
  );
};

export default MainFooter;
