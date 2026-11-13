# 0014 — `time_band` is never stored; bands ≤20 / 21–30 / 31+

- **Status:** Accepted · 12 Nov 2026
- **Answers:** spec §11 Q4 (server- or client-derived `time_band`?)
- **Also fixes:** the `Under 30 min` chip didn't line up with the rev 3 bands
  (≤20 / 21–35 / 36+).

## Decision

- `time_band` is **never stored**. It is one shared **pure function of
  `total_time_min`**, with its constants and tests, used identically by client
  and server.
- Bands: **`≤20` / `21–30` / `31+`**.
- The `Under 30 min` chip = bands 1 + 2, i.e. `total_time_min ≤ 30`
  (inclusive).

## Consequences

Changing the bands later is a code change with no data migration. v2 stored
`t20/t21_35/t36plus`; that is not carried over.

## Spec impact (rev 4, §9)

`time_band` row: "derived on the fly from `total_time_min`, never stored;
`≤20` / `21–30` / `31+`". §2: chip definition.
