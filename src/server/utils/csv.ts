/** Split one CSV record (no embedded newlines in line). RFC 4180-style quoted fields. */
export function parseCsvLine(line: string): string[] {
  const out: string[] = []
  let cur = ''
  let i = 0
  let inQuotes = false
  while (i < line.length) {
    const c = line[i]
    if (inQuotes) {
      if (c === '"') {
        if (line[i + 1] === '"') {
          cur += '"'
          i += 2
          continue
        }
        inQuotes = false
        i++
        continue
      }
      cur += c
      i++
      continue
    }
    if (c === '"') {
      inQuotes = true
      i++
      continue
    }
    if (c === ',') {
      out.push(cur)
      cur = ''
      i++
      continue
    }
    cur += c
    i++
  }
  out.push(cur)
  return out
}

/** Yield logical CSV rows; newlines inside double-quoted fields are kept in the field. */
export function* iterateCsvRecords(csv: string): Generator<string[]> {
  let rowStart = 0
  let i = 0
  let inQuotes = false
  while (i < csv.length) {
    const c = csv[i]
    if (c === '"') {
      if (inQuotes && csv[i + 1] === '"') {
        i += 2
        continue
      }
      inQuotes = !inQuotes
      i++
      continue
    }
    if (!inQuotes && c === '\n') {
      const slice = csv.slice(rowStart, i)
      rowStart = i + 1
      i = rowStart
      if (slice.length > 0 || slice.includes(',')) {
        const line = slice.endsWith('\r') ? slice.slice(0, -1) : slice
        if (line.length) yield parseCsvLine(line)
      }
      continue
    }
    if (!inQuotes && c === '\r' && csv[i + 1] === '\n') {
      const slice = csv.slice(rowStart, i)
      rowStart = i + 2
      i = rowStart
      if (slice.length) yield parseCsvLine(slice)
      continue
    }
    i++
  }
  if (rowStart < csv.length) {
    const slice = csv.slice(rowStart)
    if (slice.length) yield parseCsvLine(slice.endsWith('\r') ? slice.slice(0, -1) : slice)
  }
}
