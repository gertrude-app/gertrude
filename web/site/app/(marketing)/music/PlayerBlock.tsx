import cx from 'classnames';
import { ImageIcon } from 'lucide-react';
import React from 'react';

const PlayerBlock: React.FC = () => (
  <section className="relative overflow-hidden bg-slate-950 px-4 py-24 text-white xs:px-8 sm:px-12 sm:py-32 md:px-20 lg+:py-40">
    <div className="pointer-events-none absolute left-1/2 top-0 size-[48rem] -translate-x-1/2 rounded-full bg-violet-700/15 blur-[100px]" />
    <div className="relative mx-auto max-w-7xl">
      <div className="mx-auto max-w-4xl text-center">
        <p className="text-sm font-semibold uppercase tracking-[0.16em] text-fuchsia-300">
          Thoughtfully designed
        </p>
        <h2 className="mt-5 text-4xl font-semibold leading-[1.05] tracking-[-0.045em] xs:text-5xl md:text-6xl">
          A music app they’ll love using.
        </h2>
        <p className="mx-auto mt-7 max-w-3xl text-lg leading-relaxed text-violet-100/65 sm:text-xl">
          Once the boundary is set, it gets out of the way. Listeners see the music chosen
          for them in a polished player built for iPhone and iPad.
        </p>
      </div>

      <div className="mt-14 grid grid-cols-1 gap-4 sm:mt-20 sm:grid-cols-2 lg+:auto-rows-[9rem] lg+:grid-cols-12 lg+:gap-5">
        <GalleryPlaceholder
          title="Now Playing"
          body="The screen takes on the colors of each album as it plays."
          media={
            <>
              <div className="absolute inset-0 flex items-start justify-end pr-7 pt-3 xs:pr-10 sm:pr-12 sm:pt-3 lg+:pr-20 lg+:pt-0">
                <img
                  src="/music/now-playing-midnight-signals-mockup.webp"
                  alt="Gertrude Music playing Midnight Signals by Nova Vale"
                  width={818}
                  height={1670}
                  className="-mr-8 h-[92%] w-auto shrink-0 origin-bottom rotate-[9deg] sm:-mr-10 sm:-mt-10 sm:h-[104%] lg+:-mr-8 lg+:-mt-40 lg+:h-[110%]"
                />
                <img
                  src="/music/now-playing-tide-bloom-mockup.webp"
                  alt="Gertrude Music playing Tide Bloom by Mira Saint"
                  width={818}
                  height={1691}
                  className="mt-10 h-[92%] w-auto shrink-0 origin-bottom rotate-[9deg] sm:mt-12 sm:h-[104%] lg+:mt-16 lg+:h-[110%]"
                />
              </div>
            </>
          }
          className="min-h-[24rem] xs:min-h-[25rem] sm:col-span-2 sm:row-start-1 sm:min-h-[26rem] lg+:col-span-8 lg+:col-start-1 lg+:row-span-3 lg+:row-start-1 lg+:min-h-0"
          glowClassName="bg-[radial-gradient(circle_at_74%_26%,rgba(217,70,239,0.3),transparent_38%),radial-gradient(circle_at_18%_88%,rgba(124,58,237,0.32),transparent_44%)]"
        />
        <GalleryPlaceholder
          title="Playlists of their own"
          body="Kids can build playlists from the music you’ve approved."
          media={
            <>
              <div className="absolute inset-x-0 top-7 flex items-start justify-center gap-3 px-3 sm:top-8 lg+:top-6 lg+:gap-4 lg+:px-2">
                <img
                  src="/music/playlist-grid-2x2.webp"
                  alt="Four fictional album covers arranged as a two-by-two playlist mosaic"
                  width={510}
                  height={510}
                  className="w-[38%] shrink-0 rotate-[4deg] lg+:w-[34%]"
                />
                <img
                  src="/music/playlist-grid-3x3.webp"
                  alt="Nine fictional album covers arranged as a three-by-three playlist mosaic"
                  width={510}
                  height={510}
                  className="mt-10 w-[38%] shrink-0 rotate-[4deg] lg+:w-[34%]"
                />
              </div>
            </>
          }
          className="min-h-[19rem] xs:min-h-[20rem] sm:col-start-1 sm:row-start-2 sm:min-h-[21rem] lg+:col-span-4 lg+:col-start-9 lg+:row-span-2 lg+:row-start-1 lg+:min-h-0"
          glowClassName="bg-[radial-gradient(circle_at_50%_20%,rgba(217,70,239,0.24),transparent_48%)]"
        />
        <GalleryPlaceholder
          title="Choose what plays next"
          body="Kids can add songs, change the order, and keep the current song playing."
          media={
            <>
              <img
                src="/music/queue-phone.webp"
                alt="Gertrude Music queue filled with fictional songs and artists"
                width={778}
                height={1596}
                className="absolute -bottom-[16%] -right-[2%] h-[112%] w-auto rotate-[5deg] lg+:-bottom-[20%] lg+:right-[6%] lg+:h-[118%]"
              />
            </>
          }
          className="min-h-[21rem] xs:min-h-[22rem] sm:col-start-2 sm:row-start-2 sm:min-h-[21rem] lg+:col-span-4 lg+:col-start-9 lg+:row-span-3 lg+:row-start-3 lg+:min-h-0"
          glowClassName="bg-[radial-gradient(circle_at_85%_20%,rgba(139,92,246,0.28),transparent_54%)]"
        />
        <GalleryPlaceholder
          title="Great on iPad, too"
          body="Their library is just as easy to use on a bigger screen."
          media={
            <>
              <img
                src="/music/ipad-library.webp"
                alt="Gertrude Music library on iPad filled with fictional albums and playlists"
                width={1504}
                height={1959}
                className="absolute -bottom-[18%] -right-[8%] h-[108%] w-auto rotate-[3deg] lg+:-bottom-[28%] lg+:right-[7%] lg+:h-[124%]"
              />
            </>
          }
          className="min-h-[21rem] xs:min-h-[22rem] sm:col-start-1 sm:row-start-3 sm:min-h-[21rem] lg+:col-span-5 lg+:col-start-4 lg+:row-span-2 lg+:row-start-4 lg+:min-h-0"
          glowClassName="bg-[radial-gradient(ellipse_at_68%_38%,rgba(124,58,237,0.3),transparent_52%),radial-gradient(circle_at_20%_90%,rgba(217,70,239,0.18),transparent_40%)]"
        />
        <GalleryPlaceholder
          title="Tracks, albums & artists"
          body="Kids can browse every track, album, and artist you’ve approved for them."
          media={
            <div className="absolute inset-x-0 top-7 flex items-start justify-center gap-3 px-2 lg+:top-5">
              <img
                src="/music/artist-mira-saint-artwork.webp"
                alt="Portrait of the fictional artist Mira Saint"
                width={504}
                height={504}
                className="w-[40%] shrink-0 rotate-[3deg]"
              />
              <img
                src="/music/album-tide-bloom-artwork.webp"
                alt="Artwork for the fictional album Tide Bloom by Mira Saint"
                width={504}
                height={504}
                className="mt-8 w-[40%] shrink-0 rotate-[3deg]"
              />
            </div>
          }
          className="min-h-[20rem] xs:min-h-[21rem] sm:col-start-2 sm:row-start-3 sm:min-h-[21rem] lg+:col-span-3 lg+:col-start-1 lg+:row-span-2 lg+:row-start-4 lg+:min-h-0"
          glowClassName="bg-[radial-gradient(circle_at_72%_72%,rgba(217,70,239,0.24),transparent_48%)]"
        />
      </div>
    </div>
  </section>
);

export default PlayerBlock;

const GalleryPlaceholder: React.FC<{
  title: string;
  body: string;
  placeholder?: string;
  media?: React.ReactNode;
  className: string;
  glowClassName: string;
}> = ({ title, body, placeholder, media, className, glowClassName }) => (
  <div
    className={cx(
      `relative flex overflow-hidden rounded-[1.75rem] border border-white/10 bg-white/[0.045] p-5 xs:p-6 sm:rounded-[2rem] sm:p-7`,
      className,
    )}
  >
    <div className={cx(`pointer-events-none absolute inset-0`, glowClassName)} />
    {media}
    <div className="pointer-events-none absolute inset-x-0 bottom-0 z-10 h-[58%] bg-gradient-to-t from-slate-950 via-slate-950/90 to-transparent sm:h-[55%] sm:via-slate-950/80 lg+:h-2/3 lg+:via-slate-950/65" />
    <div className="relative z-20 flex w-full flex-col">
      {placeholder && (
        <span className="flex w-fit items-center gap-2 rounded-full border border-dashed border-white/15 bg-black/10 px-3 py-2 text-xs font-medium text-white/40">
          <ImageIcon className="size-4" aria-hidden />
          {placeholder}
        </span>
      )}
      <div className="mt-auto pt-6">
        <h3 className="text-xl font-semibold text-white">{title}</h3>
        <p className="mt-2 max-w-md text-sm leading-relaxed text-violet-100/65">{body}</p>
      </div>
    </div>
  </div>
);
