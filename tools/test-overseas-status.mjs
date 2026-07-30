#!/usr/bin/env node
/* Overseas enquiry queue (admin panel).
 *
 * `admin_panel/overseas-status.js` imports nothing, so plain Node can load it —
 * the same arrangement as pricing-form.js and image-upload.js, and the only
 * reason the panel's logic is testable at all given it ships unbundled with no
 * build step.
 *
 * What is being protected: an overseas enquiry is a person waiting to hear
 * back about sending something to their family. The failure that matters is
 * not a crash — it is an enquiry that quietly does not appear in the queue an
 * operator works from. Every case below is a way one could go missing.
 */

import { test, describe } from 'node:test';
import assert from 'node:assert/strict';
import {
  ALL, OPEN, TERMINAL, LABEL, TONE, NEW, CONTACTED, QUOTED, CLOSED, DECLINED,
  normalise, isOpen, nextStatuses, summarise, matches, filterInquiries
} from '../admin_panel/overseas-status.js';

const inq = (over = {}) => ({
  id: 'i1',
  customerName: 'Marcia Brown',
  contactEmail: 'marcia@example.com',
  contactPhone: '+1 718 555 0134',
  originCountry: 'Brooklyn, USA',
  recipientName: 'Delroy Brown',
  recipientPhone: '876 555 0110',
  recipientParish: 'St. Thomas',
  itemCategory: 'Food & groceries',
  itemDescription: '3 tins of ackee',
  status: NEW,
  createdAt: new Date('2026-07-01T10:00:00Z'),
  ...over
});

describe('the status vocabulary', () => {
  test('open and terminal partition every status', () => {
    assert.deepEqual([...OPEN, ...TERMINAL].sort(), [...ALL].sort());
    assert.equal(OPEN.filter((s) => TERMINAL.includes(s)).length, 0);
  });

  test('every status has an operator label and a badge tone', () => {
    for (const s of ALL) {
      assert.ok(LABEL[s], s);
      assert.ok(TONE[s], s);
    }
  });

  test('an unknown or missing status is treated as new', () => {
    // Not defensive padding: it decides whether an enquiry the panel does not
    // recognise lands in the queue or disappears from every filter. It must
    // land in the queue.
    assert.equal(normalise(undefined), NEW);
    assert.equal(normalise(null), NEW);
    assert.equal(normalise('shipped'), NEW);
    assert.equal(normalise(''), NEW);
    assert.equal(isOpen('shipped'), true);
  });
});

describe('nextStatuses', () => {
  test('never offers the status the enquiry is already in', () => {
    for (const s of ALL) {
      assert.ok(!nextStatuses(s).includes(s), s);
    }
  });

  test('offers every other status, so a mistake is always correctable', () => {
    // An operator who marks the wrong enquiry 'declined' must be able to put
    // it back. A one-way lifecycle just moves the correction into the Firebase
    // console, which is the habit this panel exists to end.
    for (const s of ALL) {
      assert.equal(nextStatuses(s).length, ALL.length - 1, s);
    }
  });

  test('leads with the likely next step', () => {
    assert.equal(nextStatuses(NEW)[0], CONTACTED);
    assert.equal(nextStatuses(CONTACTED)[0], QUOTED);
    assert.equal(nextStatuses(QUOTED)[0], CLOSED);
  });
});

describe('summarise', () => {
  test('counts each status and the open queue', () => {
    const s = summarise([
      inq({ status: NEW }), inq({ status: NEW }),
      inq({ status: QUOTED }), inq({ status: CLOSED }),
      inq({ status: DECLINED })
    ]);
    assert.equal(s.total, 5);
    assert.equal(s.open, 3);
    assert.equal(s.counts[NEW], 2);
    assert.equal(s.counts[CLOSED], 1);
  });

  test('an empty list reports zeroes, not blanks', () => {
    const s = summarise([]);
    assert.equal(s.total, 0);
    assert.equal(s.open, 0);
    assert.equal(s.counts[QUOTED], 0);
  });
});

describe('matches', () => {
  test('an empty search matches everything', () => {
    assert.equal(matches(inq(), ''), true);
    assert.equal(matches(inq(), '   '), true);
    assert.equal(matches(inq(), null), true);
  });

  test('finds an enquiry by any handle an operator has on the phone', () => {
    assert.equal(matches(inq(), 'marcia'), true);
    assert.equal(matches(inq(), 'DELROY'), true);
    assert.equal(matches(inq(), '876 555'), true);
    assert.equal(matches(inq(), 'st. thomas'), true);
    assert.equal(matches(inq(), 'ackee'), true);
    assert.equal(matches(inq(), 'i1'), true);
  });

  test('does not match something that is not there', () => {
    assert.equal(matches(inq(), 'portland'), false);
  });

  test('survives an enquiry with missing fields', () => {
    // Pre-launch documents and hand-written test data both hit this.
    assert.equal(matches({ id: 'x' }, 'x'), true);
    assert.equal(matches({ id: 'x' }, 'marcia'), false);
  });
});

describe('filterInquiries', () => {
  const list = [
    inq({ id: 'a', status: NEW, createdAt: new Date('2026-07-01') }),
    inq({ id: 'b', status: QUOTED, createdAt: new Date('2026-07-03') }),
    inq({ id: 'c', status: CLOSED, createdAt: new Date('2026-07-02') }),
    inq({ id: 'd', status: DECLINED, createdAt: new Date('2026-06-30') })
  ];

  test('defaults to the working queue', () => {
    assert.deepEqual(filterInquiries(list, {}).map((i) => i.id), ['b', 'a']);
  });

  test('"all" includes the finished ones', () => {
    assert.deepEqual(
      filterInquiries(list, { status: 'all' }).map((i) => i.id),
      ['b', 'c', 'a', 'd']
    );
  });

  test('a single status filters to exactly that status', () => {
    assert.deepEqual(filterInquiries(list, { status: CLOSED }).map((i) => i.id), ['c']);
  });

  test('search and status filter compose', () => {
    const rows = filterInquiries(
      [...list, inq({ id: 'e', status: NEW, recipientName: 'Pauline' })],
      { status: 'open', q: 'pauline' }
    );
    assert.deepEqual(rows.map((i) => i.id), ['e']);
  });

  test('an enquiry whose timestamp has not resolved sorts first, not last', () => {
    // serverTimestamp() resolves after the write, so the newest enquiry in the
    // queue is briefly the one with no date. Sorting it last would put the
    // most urgent item at the bottom of the page.
    const rows = filterInquiries(
      [...list, inq({ id: 'fresh', status: NEW, createdAt: null })],
      { status: 'open' }
    );
    assert.equal(rows[0].id, 'fresh');
  });

  test('an empty list is not an error', () => {
    assert.deepEqual(filterInquiries([], {}), []);
    assert.deepEqual(filterInquiries(null, {}), []);
  });
});
