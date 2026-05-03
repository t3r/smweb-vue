<template>
  <div class="help-view">
    <h1 class="mt-0">Help</h1>
    <p class="lead text-color-secondary">
      A practical guide to the scenery database for pilots, scenery authors, and 3D artists. You do not need to be a developer to contribute.
    </p>

    <nav class="help-toc surface-card border-round p-3 mb-4" aria-label="On this page">
      <strong class="block mb-2">On this page</strong>
      <ul class="toc-list m-0 pl-3">
        <li><router-link :to="{ path: '/help', hash: '#what-is-stored' }">What the database stores</router-link></li>
        <li><router-link :to="{ path: '/help', hash: '#models-vs-objects' }">Models and objects</router-link></li>
        <li><router-link :to="{ path: '/help', hash: '#creating-models' }">Creating and submitting models</router-link></li>
        <li><router-link :to="{ path: '/help', hash: '#placing-objects' }">Placing and editing objects</router-link></li>
        <li><router-link :to="{ path: '/help', hash: '#review-process' }">Submission and review</router-link></li>
        <li><router-link :to="{ path: '/help', hash: '#stg-heading' }">STG heading and true heading</router-link></li>
        <li><router-link :to="{ path: '/help', hash: '#elevation-offset' }">Elevation offset</router-link></li>
        <li><router-link :to="{ path: '/help', hash: '#account-merge' }">Merging author accounts</router-link></li>
        <li><router-link :to="{ path: '/help', hash: '#tips' }">Tips and good practice</router-link></li>
      </ul>
    </nav>

    <section id="what-is-stored" class="help-anchor-section mb-4">
      <Card>
      <template #title>What the database stores</template>
      <template #content>
        <p>
          This site is the front end for the <strong>FlightGear scenery database</strong>: a catalogue of community 3D models and
          where they are placed on Earth. The data lives in a central <strong>database</strong> (with map coordinates and export
          fields the scenery tools expect). On the website you browse that as <strong>models</strong>, <strong>objects</strong>,
          <strong>authors</strong>, and <strong>news</strong>—each entry is one record contributors and reviewers maintain together.
        </p>
        <p>
          The database does <em>not</em> run FlightGear; it helps authors and reviewers maintain the shared dataset. Approved
          changes are distributed to users through the normal FlightGear scenery update path (for example TerraSync), so your work
          can appear in everyone’s sim after review and export.
        </p>
      </template>
      </Card>
    </section>

    <section id="models-vs-objects" class="help-anchor-section mb-4">
      <Card>
      <template #title>Models and objects</template>
      <template #content>
        <h3 class="mt-0 text-lg">Model</h3>
        <p>
          A <strong>model</strong> is a reusable 3D asset: typically an AC3D model, its XML wrapper, textures, and metadata (name,
          author, licence such as GPL, thumbnail). One model file set can describe a building, a sign, an aircraft on static
          display, and so on. Models are listed under <router-link to="/models">Models</router-link>; each has an ID you can reference.
        </p>
        <h3 class="text-lg">Object</h3>
        <p>
          An <strong>object</strong> is a <em>placement</em>: “use model #123 here, at this latitude and longitude, with this
          heading and height tweak.” Many objects can share the same model (dozens of identical benches, many gates at an airport).
          Objects appear on the <router-link to="/map">Map</router-link> and in the
          <router-link to="/objects">Objects</router-link> list. Deleting an object removes only that placement; the underlying model
          catalogue entry remains unless you separately request a model deletion.
        </p>
        <p>
          In short: <strong>models are what you draw</strong>; <strong>objects are where you put them</strong> in the world.
        </p>
      </template>
      </Card>
    </section>

    <section id="creating-models" class="help-anchor-section mb-4">
      <Card>
      <template #title>Creating and submitting models</template>
      <template #content>
        <ol class="pl-3 m-0">
          <li class="mb-2">
            Build your model with the usual FlightGear tooling (AC3D or compatible workflow, XML, textures). Follow project licensing
            expectations (commonly GPL) and keep file sizes reasonable.
          </li>
          <li class="mb-2">
            Prepare a <strong>thumbnail</strong> image and a <strong>package</strong> of files (or use the web upload fields for
            thumbnail, AC/XML, and PNG textures) as required by the submission form.
          </li>
          <li class="mb-2">
            Sign in via <strong>Login</strong> (GitHub, Google, or GitLab). Submissions are tied to your account so reviewers can
            see who contributed and you can track <router-link to="/position-requests">Pending requests</router-link>.
          </li>
          <li class="mb-2">
            Use <router-link to="/models/add">Add model</router-link> to propose a new model. You will usually add an initial object
            position with it so the model appears somewhere sensible on first acceptance.
          </li>
          <li>
            To change an existing catalogue entry, open the model’s page and use the update flow when you are allowed to edit it.
          </li>
        </ol>
      </template>
      </Card>
    </section>

    <section id="placing-objects" class="help-anchor-section mb-4">
      <Card>
      <template #title>Placing and editing objects</template>
      <template #content>
        <p>
          New placements can be submitted from the map or object workflows in the app: you choose a <strong>model</strong>, set
          <strong>latitude and longitude</strong>, and set <strong>heading</strong>, <strong>elevation offset</strong>, and related
          fields as the forms explain. The site may infer <strong>country</strong> from the chosen coordinates for consistency with
          scenery regions.
        </p>
        <p>
          For several placements at once, <router-link to="/objects/import">Mass import objects</router-link> accepts pasted
          <code>OBJECT_SHARED</code> lines in the style used by FlightGear scenery <abbr title="scenery configuration">STG</abbr>
          files. Only <code>OBJECT_SHARED</code> lines are supported; each line must match the expected field order, and the model
          path must correspond to a model already in the database. Each submission accepts up to one hundred non-blank lines, so
          split very large pastes across several submissions.
        </p>
        <p>
          You can request updates to an existing object (move it, change heading, change offset, etc.) or request deletion of a
          placement you no longer want. Those changes also go through the queue until a reviewer accepts them.
        </p>
      </template>
      </Card>
    </section>

    <section id="review-process" class="help-anchor-section mb-4">
      <Card>
      <template #title>Submission and review</template>
      <template #content>
        <ol class="pl-3 m-0">
          <li class="mb-2">
            When you submit a model add/update/delete or an object add/update/delete, the site creates a <strong>position request</strong>
            (a queued item), not an immediate edit to the live tables visible to export.
          </li>
          <li class="mb-2">
            Open <router-link to="/position-requests">Pending requests</router-link> after signing in. You will see your own
            submissions; reviewers additionally see everyone’s queue and can open full details (including previews where
            permissions allow).
          </li>
          <li class="mb-2">
            <strong>Reviewers</strong> check licences, placement plausibility, duplicates, and technical basics. They choose
            <strong>Accept</strong> or <strong>Decline</strong>. Accepted requests are applied to the database; a short entry may
            appear on the <router-link to="/news">News</router-link> page when a request is processed.
          </li>
          <li class="mb-2">
            If a request is declined, treat the reviewer’s comment as guidance: fix the issue and submit again when appropriate.
          </li>
          <li>
            Nothing in the sim world updates instantly for all users until the scenery maintainers’ export and sync pipeline picks
            up the approved data—allow time after acceptance.
          </li>
        </ol>
      </template>
      </Card>
    </section>

    <section id="stg-heading" class="help-anchor-section mb-4">
      <Card>
      <template #title>STG heading and true heading</template>
      <template #content>
        <p>
          FlightGear scenery <strong>STG</strong> files historically express object orientation using a <strong>STG heading</strong>
          (the numeric heading field on <code>OBJECT_SHARED</code> lines in that file format). Internally, the database and many
          tools work with <strong>true heading</strong> (a consistent “compass style” convention for which way the model faces on the
          ground).
        </p>
        <p>
          The two conventions are <strong>not the same number</strong> for the same physical orientation. When you use the web forms
          to set heading, think in terms of the value the database stores (true heading). When you <strong>mass-import</strong>
          pasted STG lines, the site reads the STG heading from the line and <strong>converts it to true heading</strong> before
          storing the object, so you can paste values copied from existing scenery without hand-converting each angle.
        </p>
        <h3 class="text-lg mb-2">Conversion formulas (degrees)</h3>
        <p class="mb-2">
          Treat headings as ordinary real numbers in degrees; in practice you will usually normalize to a sensible range such as
          0°–360° after each step.
        </p>
        <p class="mb-2"><strong>From STG heading to true heading</strong> (this is what the site applies when importing
          <code>OBJECT_SHARED</code> lines):</p>
        <ul class="pl-3 mt-0 mb-3">
          <li>If STG heading is <strong>less than or equal to 180°</strong>:<br />
            <span class="help-formula">true heading = 180° − STG heading</span>
          </li>
          <li>If STG heading is <strong>greater than 180°</strong>:<br />
            <span class="help-formula">true heading = 540° − STG heading</span>
          </li>
        </ul>
        <p class="mb-2"><strong>From true heading to STG heading</strong> (for example when hand-writing a line to match a value
          you see in the database):</p>
        <ul class="pl-3 mt-0 mb-3">
          <li>If true heading is <strong>strictly less than 180°</strong>:<br />
            <span class="help-formula">STG heading = 180° − true heading</span>
          </li>
          <li>If true heading is <strong>strictly greater than 180°</strong>:<br />
            <span class="help-formula">STG heading = 540° − true heading</span>
          </li>
          <li>If true heading <strong>equals 180°</strong>, the forward rules map both <strong>STG = 0°</strong> and
            <strong>STG = 300°</strong> to the same true heading; use whichever matches the line you are editing (0° is the usual
            round value).
          </li>
        </ul>
        <p class="mb-0">
          If you edit heading directly in a form or map picker, use the same convention as the rest of the site (true heading). If
          you are comparing numbers to a raw <code>.stg</code> file, expect STG and stored values to differ unless you account for
          that conversion.
        </p>
      </template>
      </Card>
    </section>

    <section id="elevation-offset" class="help-anchor-section mb-4">
      <Card>
      <template #title>Elevation offset</template>
      <template #content>
        <p>
          Each object sits at a geographic point. FlightGear derives a <strong>ground elevation</strong> from terrain and airport
          data so the model rests on the ground rather than floating or sinking. In practice terrain meshes and sources are not
          perfect; small errors are common near buildings, bridges, or steep slopes.
        </p>
        <p>
          The <strong>elevation offset</strong> is an extra value (in metres) <strong>added on top of the computed ground elevation</strong>
          for that placement. Use a positive offset to raise the model slightly, or a negative offset to lower it, until it looks
          correct in the sim for that location and scenery version.
        </p>
        <p class="mb-0">
          When importing STG lines, an optional seventh field on an <code>OBJECT_SHARED</code> line is interpreted as this offset.
          The ground-elevation field in the middle of the STG line is part of the classic format; the database still stores your
          chosen offset separately for the placement. If you leave offset empty or zero, the object uses the terrain-derived height
          without a manual tweak.
        </p>
      </template>
      </Card>
    </section>

    <section id="account-merge" class="help-anchor-section mb-4">
      <Card>
      <template #title>Merging author accounts</template>
      <template #content>
        <p>
          The database ties models, news, and submission history to an <strong>author</strong> record. Over the years the same
          person can end up with <strong>more than one author record</strong>—for example an older “legacy” entry that used a
          different email than the one your GitHub, Google, or GitLab sign-in uses today. That split is confusing on author pages
          and can hide credit for your work.
        </p>
        <p>
          <strong>Account merge</strong> exists to combine two author records into one after you prove you control both: the
          profile keeps the <strong>lower numeric author id</strong> (“keeper”), and models, news, and linked identities from the
          other record are folded into it. Reviewers and the rest of the site then see a single author.
        </p>
        <h3 class="text-lg mb-2">How to merge</h3>
        <ol class="pl-3 m-0">
          <li class="mb-2">
            Sign in with the account you want to <strong>keep using</strong> day to day (your OAuth login).
          </li>
          <li class="mb-2">
            Open <router-link to="/account/merge">Merge accounts</router-link> (you can also reach it from your author page when
            you are signed in). Enter the <strong>other</strong> author’s email address or numeric author id—the duplicate or legacy
            record you want to absorb.
          </li>
          <li class="mb-2">
            Click <strong>Send verification email</strong>. If that author exists and has an email on file, the system queues a
            message to <em>that</em> inbox with a confirmation link.
          </li>
          <li class="mb-2">
            Open the link from the email while still signed in with <strong>this same</strong> OAuth account. You will land on a
            confirmation screen that shows a summary of the merge—use only the link from your mail and do not forward it to others.
          </li>
          <li class="mb-2">
            Read the summary (keeper id, counts, effective role). If everything looks right, choose <strong>Confirm merge</strong>; if
            not, use <strong>Cancel</strong> to abort without combining records.
          </li>
          <li class="mb-0">
            After a successful merge you are redirected to the combined author profile. If something fails, try again or contact a
            maintainer; never confirm a merge for an author you do not control.
          </li>
        </ol>
      </template>
      </Card>
    </section>

    <section id="tips" class="help-anchor-section mb-4">
      <Card>
      <template #title>Tips and good practice</template>
      <template #content>
        <ul class="pl-3 m-0">
          <li class="mb-2">
            Prefer <strong>clear descriptions and comments</strong> on submissions so reviewers understand intent (e.g. “replaces
            misplaced duplicate near runway 09”).
          </li>
          <li class="mb-2">
            Check the <router-link to="/map">Map</router-link> for existing objects before adding duplicates.
          </li>
          <li class="mb-2">
            Keep <strong>licence and authorship</strong> accurate; reviewers are expected to enforce project rules.
          </li>
          <li class="mb-0">
            For software behaviour, credits, and project background, see <router-link to="/about">About</router-link>.
          </li>
        </ul>
      </template>
      </Card>
    </section>
  </div>
</template>

<style scoped>
.help-view {
  max-width: 52rem;
}
.lead {
  font-size: 1.05rem;
  line-height: 1.55;
}
.help-toc {
  border: 1px solid var(--p-content-border-color, var(--surface-border));
}
.toc-list {
  line-height: 1.7;
}
.help-anchor-section {
  scroll-margin-top: 5rem;
}
.help-formula {
  font-family: ui-monospace, monospace;
  font-size: 0.95rem;
}
</style>
