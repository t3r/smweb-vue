# SQL injection prevention

**Approach:** bound parameters for all request-derived values, plus strict validation at controllers (`validateId`, `validateCountry`, etc.) → `400` before the DB.

- **Parameterization:** raw SQL uses `replacements` only; no string interpolation of user or submission data.
- **Dynamic SQL:** allowlists / fixed branches for sort keys and similar — never user-controlled identifiers.
- **Escaping** is not used as the primary defense; parameterization makes it unnecessary.

**Code:** `src/server/utils/validateInput.ts`; repositories use Sequelize `replacements` throughout.
