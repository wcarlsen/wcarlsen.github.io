module.exports = {
  extends: ['config:recommended'],
  branchPrefix: 'update/renovate/',
  username: 'renovate',
  gitAuthor: 'Renovate Bot <bot@renovateapp.com>',
  onboarding: false,
  requireConfig: 'optional',
  platform: 'github',
  repositories: [
    'wcarlsen/wcarlsen.github.io',
  ],
  'pre-commit': {
    enabled: true,
  },
  nix: {
    enabled: true
  },
  lockFileMaintenance: {
    enabled: true
  },
};
