import React from 'react';
import { ChevronLeftIcon, ChevronRightIcon } from './Icons';

interface PaginationProps {
  currentPage: number;
  totalPages: number;
  onPageChange: (page: number) => void;
}

function getPageNumbers(current: number, total: number): (number | string)[] {
  if (total <= 7) {
    return Array.from({ length: total }, (_, i) => i + 1);
  }

  if (current <= 3) {
    return [1, 2, 3, 4, 5, `...`, total];
  }

  if (current >= total - 2) {
    return [1, `...`, total - 4, total - 3, total - 2, total - 1, total];
  }

  return [1, `...`, current - 1, current, current + 1, `...`, total];
}

const Pagination: React.FC<PaginationProps> = ({
  currentPage,
  totalPages,
  onPageChange,
}) => (
  <div className="flex items-center gap-1">
    <button
      onClick={() => onPageChange(currentPage - 1)}
      disabled={currentPage <= 1}
      className="p-2 text-slate-500 hover:text-slate-900 hover:bg-slate-100 rounded-lg transition-all disabled:opacity-40 disabled:cursor-not-allowed disabled:hover:bg-transparent"
    >
      <ChevronLeftIcon className="w-5 h-5" />
    </button>
    <div className="flex items-center gap-1 px-2">
      {getPageNumbers(currentPage, totalPages).map((pageNum, idx) =>
        pageNum === `...` ? (
          <span key={`ellipsis-${idx}`} className="px-2 text-slate-400">
            ...
          </span>
        ) : (
          <button
            key={pageNum}
            onClick={() => onPageChange(pageNum as number)}
            className={`min-w-[36px] h-9 px-3 rounded-lg text-sm font-medium transition-all ${
              pageNum === currentPage
                ? `bg-gradient-to-r from-brand-violet to-brand-fuchsia text-white shadow-sm`
                : `text-slate-600 hover:bg-slate-100`
            }`}
          >
            {pageNum}
          </button>
        ),
      )}
    </div>
    <button
      onClick={() => onPageChange(currentPage + 1)}
      disabled={currentPage >= totalPages}
      className="p-2 text-slate-500 hover:text-slate-900 hover:bg-slate-100 rounded-lg transition-all disabled:opacity-40 disabled:cursor-not-allowed disabled:hover:bg-transparent"
    >
      <ChevronRightIcon className="w-5 h-5" />
    </button>
  </div>
);

export default Pagination;
