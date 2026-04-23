<template>
  <div class="about-view">
    <h1 class="mt-0">About</h1>
    <p>
      For decades, our PHP-based scenery platform has been a trusted cornerstone of the FlightGear community — reliably serving thousands of 3D object placements and worldwide position data to simmers across the globe. <br />
      Now we've rebuilt it from the ground up. The new platform is based on a modern Vue 3 + Node.js + PostgreSQL architecture, is fully open source, and available on <a href="https://github.com/t3r/smweb-vue">GitHub</a>.
    </p>
    <p>The codebase is backed by hundreds of automated tests and a continuous build and deployment pipeline, so contributions are easier, improvements and fixes reach you faster.<br />
      Dependencies are kept up to date automatically via Dependabot, keeping the platform secure and maintainable long into the future. <br />
      Contributing to the dataset has never been easier. A streamlined workflow lets community members submit and manage 3D scenery objects and their geographic positions with less friction, while a cleaner review process helps maintainers evaluate and approve contributions efficiently. <br />
      Role-based access control ensures that contributors, reviewers, and administrators each have clearly defined permissions — keeping collaboration both open and well-organized.
    </p>
    <p>Same trusted data. Modern tools. <br />
      Built by the community, for the community.
    </p>

    <p class="text-color-secondary lead">
      <a href="https://www.flightgear.org/" target="_blank">FlightGear</a> is a free, open-source flight simulator built by volunteers around the world. Its world is not bought in a box: it is stitched together from
      terrain, navaids, airports, and countless 3D models
      placed by the community—buildings, signs, antennas, static aircraft, and the small details that make low-and-slow flying feel alive.
    </p>

    <p>
      The <strong>scenery database</strong> is the catalogue behind that effort: records of shared models, who authored them, and where objects sit on the
      globe. For years it powered submissions and browsing for anyone who wanted to contribute or reuse work under the project’s licensing. What you see on
      this site is the next step in that lineage—a modern web application that talks to the same data, helps authors and curators manage models and object
      positions, and offers a map and search so pilots and scenery builders can explore what exists and where.
    </p>

    <p class="text-color-secondary">
      This software does not replace the sim itself; it supports the people who feed it. If you add or update a model, or request a position change, your changes will
      be exported to the world scenery and distributed to all our users by TerraSync, making you part of a global community.
    </p>

    <Card class="mt-4">
      <template #title>Credits</template>
      <template #content>
        <ul class="about-credits list-none p-0 m-0">
          <li class="py-2 border-bottom-1 surface-border">
            <strong>Jon Stockill</strong> — for creating the original scenery database.
          </li>
          <li class="py-2 border-bottom-1 surface-border">
            <strong>Martin Spott</strong> — for porting it to PostgreSQL and hosting it in the first years.
          </li>
          <li class="py-2 border-bottom-1 surface-border">
            <strong>Julien Nguyen</strong> — for maintaining the long-running PHP version of the scenery site.
          </li>
           <li class="py-2 border-bottom-1 surface-border">
            <strong>David Megginson</strong> — for providing <a href="https://ourairports.com">ourairports.com</a> from where we get the airports data used in this site.
          </li>
          <li class="py-2 m-0">
            <strong>Everyone who contributed over the years</strong> — authors and editors of models, keepers of data, and everyone who reported bugs, tested
            changes, and fixed things so the database and tools kept working.
          </li>
        </ul>
      </template>
    </Card>
  </div>
</template>

<style scoped>
.about-view {
  max-width: 52rem;
}
.lead {
  font-size: 1.05rem;
  line-height: 1.55;
}
.about-credits li:last-child {
  border-bottom: none !important;
}
</style>
