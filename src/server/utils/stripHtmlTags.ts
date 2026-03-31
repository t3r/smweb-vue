/**
 * Remove HTML/XML-style angle-bracket segments so markup is not stored verbatim.
 * Plain text like "a < b" is preserved (no `>` closing a tag).
 */
export function stripHtmlTags(input: string): string {
  let s = input
  let prev = ''
  const re = /<[^>]*>/g
  while (s !== prev) {
    prev = s
    s = s.replace(re, '')
  }
  return s
}
