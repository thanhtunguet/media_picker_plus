# Media Picker Plus Documentation

This directory contains the Docusaurus documentation site for Media Picker Plus.

## Getting Started

### Prerequisites

- Node.js version 20.0 or above
- npm or yarn

### Installation

```bash
npm install
```

### Development

Start the development server:

```bash
npm start
```

This command starts a local development server and opens up a browser window. Most changes are reflected live without having to restart the server.

### Build

Generate static content into the `build` directory:

```bash
npm run build
```

This command generates static content into the `build` directory and can be served using any static contents hosting service.

### Serve

Serve the built site locally:

```bash
npm run serve
```

## GitHub Pages Deployment

The documentation is automatically built and deployed to GitHub Pages via GitHub Actions when changes are pushed to the `main` branch.

### Setup

1. Go to your repository settings on GitHub
2. Navigate to **Pages** under **Settings**
3. Under **Source**, select **GitHub Actions** (not "Deploy from a branch")
4. The workflow will automatically deploy when changes are pushed to `docs/` or the workflow file

### Manual Deployment

You can also trigger a manual deployment by:
1. Going to the **Actions** tab in your repository
2. Selecting **Build and Deploy Documentation** workflow
3. Clicking **Run workflow**

The documentation will be available at: `https://thanhtunguet.github.io/media_picker_plus/`

## Documentation Structure

- `docs/` - Documentation markdown files
- `blog/` - Blog posts (optional)
- `src/` - React components and pages
- `static/` - Static assets (images, etc.)

## Learn More

- [Docusaurus Documentation](https://docusaurus.io/docs)
- [Docusaurus API Reference](https://docusaurus.io/docs/api)
