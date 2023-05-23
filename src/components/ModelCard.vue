<script setup>
import ModelImage from './ModelImage.vue';
import AuthorLink from './AuthorLink.vue';
import ModelGroupLink from './ModelGroupLink.vue';

defineProps(["id","title","description","authorId","authorName","filename","modelGroupName","modelGroupId","thumb","files"]);
</script>

<template>
  <div class="card">
    <ModelImage :title="title" :description="description" :imageData="thumb" :id="id"/>
    <div class="card-body">
      <h5 class="card-title">{{ title }}</h5>
      <h6 class="card-subtitle mb-2 text-body-secondary">{{ description }}</h6>
      <p class="card-text">
        This model was created by <AuthorLink :id="authorId" class="card-link">{{ authorName }}</AuthorLink>.
        It belongs to the group of <ModelGroupLink :id="modelGroupId">{{ modelGroupName }}</ModelGroupLink> models and 
        will be loaded into the scenery as <b>{{ filename }}</b>.
      </p>
      <p class="card-text">
        <h5>The model is made of these file(s)
         <a class="btn btn-primary" href="getModelTarballUrl(model.id)" role="button"><i class="bi bi-cloud-arrow-down"></i> Download</a>
        </h5>
        <table class="table">
          <thead>
            <tr>
              <th scope="col">Filename</th>
              <th scope="col">Size</th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="file in files">
              <td><a href="getModelFileUrl(id,file.filename)">{{ file.filename }}</a></td>
              <td>{{ file.filesize }}</td>
            </tr>
          </tbody>
        </table>
      </p>
    </div>
  </div>
</template>
