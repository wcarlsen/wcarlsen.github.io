module.exports = {
  branchPrefix: 'update/renovate/',
  username: 'renovate-sa',
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
  packageRules: [
    {
      matchUpdateTypes: [
        'digest',
        'lockFileMaintenance',
        'patch',
        'pin',
      ],
      minimumReleaseAge: '1 day',
      automerge: false,
      matchCurrentVersion: '!/(^0|alpha|beta)/',
      dependencyDashboard: true,
    },
    {
      matchUpdateTypes: [
        'minor'
      ],
      minimumReleaseAge: '7 day',
      automerge: false,
      matchCurrentVersion: '!/(^0|alpha|beta)/',
      dependencyDashboard: true,
    },
    {
      matchUpdateTypes: [
        'major'
      ],
      minimumReleaseAge: '14 day',
      automerge: false,
      dependencyDashboard: true,
    },
  ],
};