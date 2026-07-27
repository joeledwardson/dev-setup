import * as path from 'node:path';
import { defineConfig } from '@rspress/core';
import pluginMermaid from 'rspress-plugin-mermaid';
import pluginContentPadding from 'rspress-plugin-content-padding';
import pluginFocusMode from 'rspress-plugin-focus-mode';

export default defineConfig({
  root: path.join(__dirname, 'docs'),
  // GH Pages serves at /<repo>/. The deploy workflow sets DOCS_BASE=/dev-setup/;
  // local `task docs:serve` leaves it unset so dev stays at '/'.
  base: process.env.DOCS_BASE ?? '/',
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
  plugins: [pluginMermaid(), pluginContentPadding(), pluginFocusMode()],
  globalStyles: path.join(__dirname, 'styles/index.css'),
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
