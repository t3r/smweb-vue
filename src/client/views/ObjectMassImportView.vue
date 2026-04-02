<template>
  <div class="mass-import-view">
    <h1 class="mt-0">Mass import objects</h1>
    <p class="text-color-secondary mt-0 mb-4">
      Paste <code>OBJECT_SHARED</code> lines from STG files (same format as the legacy site). Up to
      {{ maxLines }} non-blank lines per submission. Ground elevation in the line is ignored; only the optional
      elevation offset (7th field) is used. Heading is converted from STG to true heading like the old form.
    </p>

    <ul class="help-list mb-4">
      <li>Only <strong>OBJECT_SHARED</strong> lines; no <code>OBJECT_STATIC</code> or <code>OBJECT_SIGN</code>.</li>
      <li>Model path must exist in the database (matched by XML filename, e.g. <code>localizer.xml</code>).</li>
      <li>Example: <code>OBJECT_SHARED Models/Airport/localizer.xml 121.337467 31.179872 2.47 267.03</code></li>
    </ul>

    <template v-if="!success">
      <Card>
        <template #content>
          <div class="form-grid">
            <label for="mass-stg">STG lines <span class="required">*</span></label>
            <textarea
              id="mass-stg"
              v-model="stg"
              class="stg-textarea w-full"
              rows="18"
              spellcheck="false"
              placeholder="OBJECT_SHARED Models/…"
            />

            <template v-if="needsGuestEmail">
              <label for="mass-email">Email <span class="required">*</span></label>
              <InputText
                id="mass-email"
                v-model="email"
                type="email"
                maxlength="50"
                class="w-full"
                autocomplete="email"
              />
            </template>

            <label for="mass-comment">Comment <span class="required">*</span></label>
            <InputText
              id="mass-comment"
              v-model="comment"
              maxlength="100"
              class="w-full"
              placeholder="Short note for reviewers (max 100 characters, no | )"
            />
          </div>

          <div class="actions mt-4 flex flex-wrap gap-2">
            <Button
              type="button"
              label="Check lines"
              severity="secondary"
              :loading="previewLoading"
              :disabled="submitLoading"
              @click="runPreview"
            />
            <Button
              type="button"
              label="Submit for review"
              :loading="submitLoading"
              :disabled="previewLoading || !canSubmit"
              @click="submit"
            />
          </div>

          <div v-if="previewErrorLines.length > 0" class="preview-feedback preview-feedback--warn mt-4">
            <p class="mt-0 mb-2 font-medium">Some lines need fixing:</p>
            <ul class="line-error-list">
              <li v-for="(e, idx) in previewErrorLines" :key="idx">
                <strong>Line {{ e.line }}</strong>: {{ e.messages.join('; ') }}
                <pre class="line-snippet">{{ e.text }}</pre>
              </li>
            </ul>
          </div>
        </template>
      </Card>
    </template>

    <template v-else>
      <Card>
        <template #content>
          <p class="m-0 mb-3 text-color-secondary">Request #{{ successId ?? '?' }} has been submitted.</p>
          <router-link to="/objects">
            <Button label="Browse objects" icon="pi pi-list" />
          </router-link>
        </template>
      </Card>
    </template>

    <ErrorDialog v-model:visible="errorDialogVisible" :message="error" @cleared="onErrorDialogCleared" />
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted, watch } from 'vue'
import { useAuthStore } from '@/stores/auth'
import ErrorDialog from '@/components/ErrorDialog.vue'
import { useErrorDialog } from '@/composables/useErrorDialog'
import { useAppToast } from '@/composables/useAppToast'
import Button from 'primevue/button'

const auth = useAuthStore()
const { toastSuccess, toastWarn, toastInfo } = useAppToast()

/** Guests and signed-in users without an email on the account must type one. */
const needsGuestEmail = computed(
  () => !auth.isAuthenticated || !(auth.user?.email && String(auth.user.email).trim())
)

const maxLines = 100

const stg = ref('')
const email = ref('')
const comment = ref('')
const { error, errorDialogVisible, clearError, showError, onErrorDialogCleared } = useErrorDialog()
const success = ref(false)
const successId = ref<number | null>(null)
const previewLoading = ref(false)
const submitLoading = ref(false)
const previewErrorLines = ref<{ line: number; text: string; messages: string[] }[]>([])
const previewOkCount = ref<number | null>(null)

const canSubmit = computed(() => {
  const hasComment =
    comment.value.trim().length > 0 && comment.value.length <= 100 && !comment.value.includes('|')
  if (!stg.value.trim().length || !hasComment) return false
  if (!needsGuestEmail.value) return true
  return email.value.trim().length > 0 && /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email.value.trim())
})

onMounted(() => {
  void auth.fetchUser()
})

watch(stg, () => {
  previewErrorLines.value = []
  previewOkCount.value = null
})

function validateFormFields(): string | null {
  if (!stg.value.trim()) return 'STG content is required'
  if (needsGuestEmail.value) {
    if (!email.value.trim()) return 'Email is required'
    if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email.value.trim())) return 'Please enter a valid email'
  }
  if (!comment.value.trim()) return 'Comment is required'
  if (comment.value.length > 100) return 'Comment must be at most 100 characters'
  if (comment.value.includes('|')) return 'Comment cannot contain |'
  return null
}

async function runPreview(): Promise<void> {
  clearError()
  previewErrorLines.value = []
  previewOkCount.value = null
  if (!stg.value.trim()) {
    showError('STG content is required')
    return
  }
  previewLoading.value = true
  try {
    const res = await fetch(auth.apiUrl('/api/submissions/objects/stg-preview'), {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      credentials: 'include',
      body: JSON.stringify({ stg: stg.value }),
    })
    const data = (await res.json().catch(() => ({}))) as {
      ok?: boolean
      lineErrors?: { line: number; text: string; messages: string[] }[]
      count?: number
    }
    if (!res.ok) {
      showError((data as { error?: string }).error || 'Preview failed')
      return
    }
    if (data.ok && typeof data.count === 'number') {
      previewOkCount.value = data.count
      toastInfo(`All ${data.count} line(s) look valid. You can submit for review.`, 'Preview')
    } else if (data.lineErrors?.length) {
      previewErrorLines.value = data.lineErrors
      toastWarn(
        `${data.lineErrors.length} line(s) need fixing — see the list below.`,
        'Preview'
      )
    } else {
      showError('Unexpected preview response')
    }
  } catch {
    showError('Network error')
  } finally {
    previewLoading.value = false
  }
}

async function submit(): Promise<void> {
  clearError()
  const v = validateFormFields()
  if (v) {
    showError(v)
    return
  }
  submitLoading.value = true
  try {
    const payload: Record<string, string> = {
      stg: stg.value,
      comment: comment.value.trim(),
    }
    if (needsGuestEmail.value) payload.email = email.value.trim()

    const res = await fetch(auth.apiUrl('/api/submissions/objects'), {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      credentials: 'include',
      body: JSON.stringify(payload),
    })
    const data = (await res.json().catch(() => ({}))) as {
      id?: number
      lineErrors?: { line: number; text: string; messages: string[] }[]
      error?: string
    }
    if (!res.ok) {
      if (data.lineErrors?.length) {
        previewErrorLines.value = data.lineErrors
        previewOkCount.value = null
      }
      showError(data.error || 'Submit failed')
      return
    }
    if (data.id != null) {
      success.value = true
      successId.value = data.id
      toastSuccess(`Your objects were queued for review (request #${data.id}).`, 'Submitted')
    } else {
      showError('Unexpected response')
    }
  } catch {
    showError('Network error')
  } finally {
    submitLoading.value = false
  }
}
</script>

<style scoped>
.form-grid {
  display: grid;
  grid-template-columns: minmax(8rem, 12rem) 1fr;
  gap: 0.75rem 1rem;
  align-items: start;
}
@media (max-width: 600px) {
  .form-grid {
    grid-template-columns: 1fr;
  }
}
.required {
  color: var(--p-red-500);
}
.help-list {
  margin: 0;
  padding-left: 1.25rem;
  color: var(--p-text-muted-color);
  font-size: 0.9375rem;
}
.stg-textarea {
  font-family: ui-monospace, monospace;
  font-size: 0.8125rem;
  padding: 0.5rem 0.75rem;
  border-radius: var(--p-border-radius-md);
  border: 1px solid var(--p-content-border-color);
  background: var(--p-content-background);
  color: var(--p-text-color);
  resize: vertical;
  min-height: 12rem;
}
.line-error-list {
  margin: 0;
  padding-left: 1.25rem;
  max-height: 16rem;
  overflow: auto;
}
.line-snippet {
  margin: 0.25rem 0 0 0;
  font-size: 0.75rem;
  white-space: pre-wrap;
  word-break: break-all;
  opacity: 0.9;
}
.preview-feedback {
  padding: 0.75rem 1rem;
  border-radius: var(--p-border-radius-md);
  border: 1px solid var(--p-content-border-color);
}
.preview-feedback--warn {
  background: var(--p-message-warn-background, color-mix(in srgb, var(--p-amber-500) 12%, transparent));
  border-color: var(--p-message-warn-border-color, var(--p-amber-500));
  color: var(--p-message-warn-color, var(--p-text-color));
}
.text-color-secondary {
  color: var(--p-text-muted-color);
}
.font-medium {
  font-weight: 600;
}
</style>
