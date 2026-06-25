import * as path from 'node:path';
import { defineConfig } from '@rspress/core';
import pluginMermaid from 'rspress-plugin-mermaid';

export default defineConfig({
  root: path.join(__dirname, 'docs'),
  // base: '/dev-setup/',   // <-- GH Pages knob: set to '/<repo>/' when deploying to a project page
  lang: 'en',
  title: "Joel's Dev Setup",
  description: 'NixOS workstation notes, configs and references',
  icon: '/rspress-icon.png',
  logo: {
    light: '/rspress-light-logo.png',
    dark: '/rspress-dark-logo.png',
  },
  search: {
    // index code-block contents so code is searchable too
    codeBlocks: true,
  },
  plugins: [pluginMermaid()],
  themeConfig: {
    socialLinks: [
      {
        icon: 'github',
        mode: 'link',
        content: 'https://github.com/joeledwardson/dev-setup',
      },
    ],
  },
});
