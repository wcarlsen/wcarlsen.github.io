module.exports = {
  branchPrefix: 'update/renovate/',
  username: 'renovate-sa',
  onboarding: false,
  requireConfig: 'optional',
  configMigration: true,
  platform: 'github',
  prHourlyLimit: 0,
  prConcurrentLimit: 0,
  branchConcurrentLimit: 0,
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
    {
      matchDatasources: ["github-releases"],
      matchDepNames: ["hashicorp/terraform"],
      enabled: false
    }
  ],
  customManagers: [
    {
      customType: "regex",
      fileMatch: ["^versions.tf$"],
      matchStrings: ["required_version\\s=\\s\"(?<currentValue>.*?)\""],
      depNameTemplate: "opentofu/opentofu",
      datasourceTemplate: "github-releases"
    },
  ]
};
