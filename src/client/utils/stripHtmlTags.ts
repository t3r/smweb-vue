/**
 * Remove HTML/XML-style tags from untrusted text so markup is not interpreted as DOM.
 * Plain text and comparisons like "a < b" are preserved (no `>` closing a tag).
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
