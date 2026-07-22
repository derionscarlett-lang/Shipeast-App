/* ═══════════════════════════════════════════════════════════════
   Overseas enquiry handling — admin panel copy.
   Source of truth: SCHEMA.md §overseasInquiries
   ═══════════════════════════════════════════════════════════════

   Mirrors customer_app/lib/models/overseas_inquiry.dart. Edit both, or
   neither.

   Imports nothing on purpose, for the same reason image-upload.js and
   pricing-form.js do: the panel ships unbundled with no build step, so a
   module free of Firebase imports loads in plain Node and its logic can be
   pinned by `node --test` instead of by clicking through a browser.

   Note on labels: LABEL below is operator-facing and deliberately differs from
   the Dart `OverseasStatus.label`, which is customer-facing. An operator wants
   the queue state ("Quoted"); the customer wants to know whether they are
   waiting on us or we on them ("Quote sent").                             */

export const NEW = 'new';
export const CONTACTED = 'contacted';
export const QUOTED = 'quoted';
export const CLOSED = 'closed';
export const DECLINED = 'declined';

export const ALL = [NEW, CONTACTED, QUOTED, CLOSED, DECLINED];

/** Still somebody's responsibility. This is the queue. */
export const OPEN = [NEW, CONTACTED, QUOTED];

export const TERMINAL = [CLOSED, DECLINED];

export const LABEL = {
  [NEW]: 'New',
  [CONTACTED]: 'Contacted',
  [QUOTED]: 'Quoted',
  [CLOSED]: 'Closed',
  [DECLINED]: 'Declined'
};

/** Badge tone, matching the .bg-* classes in styles.css. */
export const TONE = {
  [NEW]: 'brand',
  [CONTACTED]: 'info',
  [QUOTED]: 'warning',
  [CLOSED]: 'success',
  [DECLINED]: 'danger'
};

/** An unrecognised or missing status is a document that was just written. */
export function normalise(raw) {
  return ALL.indexOf(raw) > -1 ? raw : NEW;
}

export function isOpen(raw) {
  return OPEN.indexOf(normalise(raw)) > -1;
}

/* The statuses the panel offers next.
   Every status stays reachable — an operator who marks the wrong enquiry
   'declined' must be able to put it back, and a rule that traps them there
   just moves the correction into the Firebase console. What this does is
   order the list so the likely next step is first, and drop the current
   status, which is not a change. */
export function nextStatuses(current) {
  const from = normalise(current);
  const preferred = {
    [NEW]: [CONTACTED, QUOTED, DECLINED, CLOSED],
    [CONTACTED]: [QUOTED, CLOSED, DECLINED, NEW],
    [QUOTED]: [CLOSED, CONTACTED, DECLINED, NEW],
    [CLOSED]: [CONTACTED, QUOTED, DECLINED, NEW],
    [DECLINED]: [NEW, CONTACTED, QUOTED, CLOSED]
  }[from];
  return preferred.filter(function (s) { return s !== from; });
}

/** Counts per status, plus the open total the page headline reports. */
export function summarise(list) {
  const counts = {};
  ALL.forEach(function (s) { counts[s] = 0; });
  let open = 0;
  (list || []).forEach(function (i) {
    const s = normalise(i && i.status);
    counts[s] += 1;
    if (isOpen(s)) open += 1;
  });
  return { counts: counts, open: open, total: (list || []).length };
}

/* Free-text search across the fields an operator actually has to hand: a
   customer on the phone gives their name or the reference; a courier partner
   gives the recipient or the parish. */
export function matches(inquiry, term) {
  const q = String(term == null ? '' : term).trim().toLowerCase();
  if (!q) return true;
  const haystack = [
    inquiry.id,
    inquiry.customerName,
    inquiry.contactEmail,
    inquiry.contactPhone,
    inquiry.recipientName,
    inquiry.recipientPhone,
    inquiry.recipientParish,
    inquiry.originCountry,
    inquiry.itemCategory,
    inquiry.itemDescription
  ].map(function (v) { return String(v == null ? '' : v).toLowerCase(); }).join(' ');
  return haystack.indexOf(q) > -1;
}

/* Filter + sort in one place so the table and the counts cannot disagree.
   `status` is a single status, 'open' for the working queue, or 'all'.
   Newest first, and an enquiry whose serverTimestamp has not resolved yet
   sorts to the top rather than vanishing — it is the newest thing there is. */
export function filterInquiries(list, opts) {
  const o = opts || {};
  const status = o.status || 'open';
  const rows = (list || []).filter(function (i) {
    const s = normalise(i.status);
    if (status === 'all') return matches(i, o.q);
    if (status === 'open') return isOpen(s) && matches(i, o.q);
    return s === status && matches(i, o.q);
  });
  return rows.sort(function (a, b) {
    const at = a.createdAt ? a.createdAt.getTime() : Infinity;
    const bt = b.createdAt ? b.createdAt.getTime() : Infinity;
    return bt - at;
  });
}
