# Deployment

Since Docsify renders at runtime, deployment is just "serve static files." All you need to host is the folder containing `index.html` + your Markdown files + `.nojekyll` (for GitHub Pages).

> If using `routerMode: 'history'` (no `#` in URLs), the host **must** rewrite unknown paths to `index.html`. With the default `hash` mode, no rewrite rules are needed.

## Contents

- [GitHub Pages](#github-pages)
- [GitLab Pages](#gitlab-pages)
- [Netlify](#netlify)
- [Vercel](#vercel)
- [Firebase Hosting](#firebase-hosting)
- [AWS Amplify](#aws-amplify)
- [Nginx](#nginx)
- [Docker](#docker)
- [Stormkit / Kinsta / DeployHQ](#stormkit--kinsta--deployhq)
- [Recap](#recap)

---

## GitHub Pages

Three layouts are supported:

- `docs/` folder on `main`
- root of `main`
- `gh-pages` branch

Recommended: put your site in `./docs` on `main`, then in repo Settings → Pages, set source = "main branch / `docs` folder".

Always create an empty `.nojekyll` file in the deploy folder so files starting with `_` (e.g. `_sidebar.md`) are served.

## GitLab Pages

`.gitlab-ci.yml`:

```yaml
pages:
  stage: deploy
  script:
    - mkdir .public
    - cp -r * .public
    - mv .public public
  artifacts:
    paths:
      - public
  only:
    - master
```

If the site is under `./docs`, replace the `cp` line with `cp -r docs/. public`.

## Netlify

1. New site → connect Git provider.
2. **Base directory**: `docs` (or your folder).
3. **Build command**: leave blank.
4. **Publish directory**: `docs/`.

For HTML5 (`history`) routing, add a `_redirects` file in the publish dir:

```text
/*    /index.html   200
```

## Vercel

```bash
npm i -g vercel
cd docs
vercel
```

## Firebase Hosting

```bash
npm i -g firebase-tools
firebase init   # choose Hosting; pick public dir, e.g. "site"
docsify init ./site
firebase deploy
```

`firebase.json`:

```json
{
  "hosting": {
    "public": "site",
    "ignore": ["firebase.json", "**/.*", "**/node_modules/**"]
  }
}
```

## AWS Amplify

1. Set `routerMode: 'history'` in `index.html`.
2. Connect repo in the Amplify console.
3. Optional `amplify.yml`:

   ```yaml
   version: 0.1
   frontend:
     phases:
       build:
         commands:
           - echo "Nothing to build"
     artifacts:
       baseDirectory: /docs
       files:
         - '**/*'
     cache:
       paths: []
   ```

4. Add redirect rules (order matters):

   | Source | Target | Type |
   | --- | --- | --- |
   | `/<*>.md` | `/<*>.md` | 200 (Rewrite) |
   | `/<*>.png` | `/<*>.png` | 200 (Rewrite) |
   | `/<*>` | `/index.html` | 200 (Rewrite) |

## Nginx

Hash mode (default):

```nginx
server {
  listen 80;
  server_name docs.example.com;
  location / {
    alias /path/to/dir/of/docs/;
    index index.html;
  }
}
```

History mode:

```nginx
server {
  listen 80;
  server_name docs.example.com;
  root /path/to/dir/of/docs;
  index index.html;
  location / { try_files $uri $uri/ /index.html; }
}
```

## Docker

`Dockerfile`:

```dockerfile
FROM node:latest
LABEL description="Docsify static site"
WORKDIR /docs
RUN npm install -g docsify-cli@latest
EXPOSE 3000/tcp
ENTRYPOINT docsify serve .
```

Build & run:

```bash
docker build -t docsify/demo .
docker run -itp 3000:3000 -v "$(pwd):/docs" docsify/demo
```

## Stormkit / Kinsta / DeployHQ

These are static-hosting services. Connect the repo and set the publish directory to `docs/` (no build command). DeployHQ is a deployment automator that pushes files to your own SSH/FTP/cloud target — it doesn't host.

## Recap

- Hash mode (`/#/page`) needs no special server config — works anywhere static files can be served.
- History mode requires URL rewrites to `index.html`.
- Always include `.nojekyll` on GitHub Pages.
- Pin your CDN version (e.g. `docsify@5.0.0-rc.4` or `docsify@4.13.1`) so unexpected releases don't break the site.
