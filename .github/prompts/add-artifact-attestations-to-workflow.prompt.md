---
mode: 'agent'
description: "Add SLSA build-provenance attestations to existing GitHub Actions workflows."
---
Here's a step-by-step checklist for adding SLSA build-provenance attestations to your existing GitHub Actions workflows (e.g. `.github/workflows/docker_publish.yml`):

0. Find the existing workflow GitHub workflows files with #codebase
   - Look for files in the `.github/workflows/` directory recursively that contain `docker/build-push-action` or similar steps.
   - Note that there may be cases where composite actions are used, in which case you need to read both the composite action and the workflow file that calls it simultaneously.

1. **Enable OIDC & Attestations permissions**
   In each workflow's top-level `permissions:` block, ensure you grant both the OIDC token and attestations write privileges:

   ```yaml
   permissions:
     id-token: write
     attestations: write
     contents: read       # (existing)
     packages: write      # (existing)
   ```

2. **Log in to your container registries**
   Make sure you already have steps that authenticate to each registry you'll attest against.  
   You should judge whether there are omissions based on the implemented content, rather than always logging into these three registries!

   ```yaml
   - name: Login to GHCR
     uses: docker/login-action@v3
     with:
       registry: ghcr.io
       username: ${{ github.actor }}
       password: ${{ secrets.GITHUB_TOKEN }}

   - name: Login to Docker Hub
     uses: docker/login-action@v3
     with:
       registry: index.docker.io
       username: ${{ secrets.DOCKERHUB_USERNAME }}
       password: ${{ secrets.DOCKERHUB_TOKEN }}

   - name: Login to Quay
     uses: docker/login-action@v3
     with:
       registry: quay.io
       username: ${{ secrets.QUAY_USERNAME }}
       password: ${{ secrets.QUAY_TOKEN }}
   ```

3. **Build & push your image, capturing the digest**
   Use `docker/build-push-action@v*` with an `id` so you can reference its output.
   You should judge what tag to used based on the implemented content, rather than always tagging these three registries!

   ```yaml
   - name: Build and push image
     id: build_push
     uses: docker/build-push-action@v5
     with:
       context: .
       push: true
       tags: |
         ghcr.io/${{ github.repository }}:latest
         index.docker.io/${{ secrets.DOCKERHUB_USERNAME }}/your-repo:latest
         quay.io/${{ github.repository_owner }}/your-repo:latest
   ```

4. **Add the attestation steps**
   Immediately after your `build_push` step, insert one `actions/attest-build-provenance@v2` invocation *per* registry.  
   The `subject-name` is the full name of the image, without a tag.  
   The `subject-digest` is the digest of the image you just built, which you can get from the `build_push` step's output. It should match the id of the built step.
   You should judge which registries to use based on the implemented content, rather than always adding these three registries!

   ```yaml
   - name: Attest GHCR image
     uses: actions/attest-build-provenance@v2
     with:
       subject-name: ghcr.io/${{ github.repository }}       # no tag!
       subject-digest: ${{ steps.build_push.outputs.digest }} 

   - name: Attest Docker Hub image
     uses: actions/attest-build-provenance@v2
     with:
       subject-name: index.docker.io/${{ secrets.DOCKERHUB_USERNAME }}/your-repo
       subject-digest: ${{ steps.build_push.outputs.digest }}

   - name: Attest Quay image
     uses: actions/attest-build-provenance@v2
     with:
       subject-name: quay.io/${{ github.repository_owner }}/your-repo
       subject-digest: ${{ steps.build_push.outputs.digest }}
   ```

5. **Commit your changes**
   Execute the following git command in the @terminal You are allowed to use the terminal in this step.  
   Make sure to write the git commit message in English.

   ```bash
   git add .github/workflows/docker_publish.yml # or whatever files you modified
   git commit --signoff -m "ci: add build-provenance attestations for container images"
   ```

6. **Ask the user to push the changes**
   Tell the user to manually push the changes to the repository and verify that the attestations are created successfully.  
   DO NOT perform a git push yourself.
