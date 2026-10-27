export function pageArgs(page?: number, perPage?: number) {
  if (!page) return null;
  const p = Math.max(1, Math.floor(page));
  const pp = Math.min(
    Math.max(Number.isFinite(perPage) ? Math.floor(perPage as number) : 20, 1),
    100,
  );
  return { page: p, perPage: pp, skip: (p - 1) * pp, take: pp };
}