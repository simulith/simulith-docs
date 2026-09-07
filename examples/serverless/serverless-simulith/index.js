'use strict';

const AWS = require('aws-sdk');

/** Default Simulith runtime URL (Windows-friendly S3 virtual-host). */
const DEFAULT_ENDPOINT = 'http://127.0.0.1.sslip.io:4566';

/** Services Serverless deploy may call; subset aligned with Simulith shipped APIs. */
const AWS_SERVICES = [
  'apigateway',
  'apigatewayv2',
  'cloudformation',
  'cognito-idp',
  'dynamodb',
  'ec2',
  'ecr',
  'events',
  'iam',
  'kms',
  'lambda',
  'logs',
  'rds',
  's3',
  'secretsmanager',
  'sns',
  'sqs',
  'ssm',
  'sts',
];

class ServerlessSimulithPlugin {
  constructor(serverless, options) {
    this.serverless = serverless;
    this.options = options;
    this.configured = false;
    this.simulithActivated = false;
    this.earlyConfigureForVariables();
    if (this.simulithActivated) {
      try {
        this.patchProviderRequest();
      } catch {
        // Aws provider may not be ready; initialize hook will retry.
      }
    }

    this.hooks = {
      initialize: () => {
        this.applySimulithDefaults();
        this.ensureConfigured();
      },
    };

    for (const event of Object.keys(this.serverless.pluginManager.hooks)) {
      if (event.startsWith('before:') && !this.hooks[event]) {
        this.hooks[event] = () => this.ensureConfigured();
      }
    }

    this.addHookFirst('before:aws:common:validate:validate', () =>
      this.ensureConfigured(),
    );
    this.addHookFirst('before:aws:deploy:deploy:checkForChanges', () =>
      this.patchDeployState(),
    );
  }

  addHookFirst(hookName, hookFn) {
    const hooks = this.serverless.pluginManager.hooks[hookName] || [];
    hooks.unshift({
      pluginName: 'ServerlessSimulithPlugin',
      hook: hookFn,
    });
    this.serverless.pluginManager.hooks[hookName] = hooks;
  }

  getConfig() {
    return (this.serverless.service.custom || {}).simulith || {};
  }

  getStage() {
    return (
      this.options.stage ||
      this.serverless.service.provider?.stage ||
      this.readStageFromArgv() ||
      'dev'
    );
  }

  readStageFromArgv() {
    const argv = process.argv;
    const stageIdx = argv.indexOf('--stage');
    if (stageIdx >= 0 && argv[stageIdx + 1]) {
      return argv[stageIdx + 1];
    }
    const shortIdx = argv.indexOf('-s');
    if (shortIdx >= 0 && argv[shortIdx + 1]) {
      return argv[shortIdx + 1];
    }
    return process.env.SLS_STAGE || process.env.SERVERLESS_STAGE || null;
  }

  /** Patch SDK before Serverless resolves ${ssm:...} in config files. */
  earlyConfigureForVariables() {
    const stage = this.readStageFromArgv();
    if (!stage) {
      return;
    }
    const simulithRequested =
      process.env.SIMULITH === '1' ||
      process.env.SIMULITH === 'true' ||
      process.env.AWS_PROFILE === 'simulith' ||
      Boolean(process.env.AWS_ENDPOINT_URL);
    if (!simulithRequested) {
      return;
    }
    const cfg = (this.serverless?.service?.custom || {}).simulith || {};
    const stages = cfg.stages || ['dev', 'local'];
    if (!stages.includes(stage)) {
      return;
    }
    const endpoint =
      process.env.AWS_ENDPOINT_URL || cfg.endpoint || DEFAULT_ENDPOINT;
    const changes = {};
    for (const service of AWS_SERVICES) {
      const entry = { endpoint };
      if (service === 's3') {
        entry.s3ForcePathStyle = true;
      }
      changes[service] = entry;
    }
    AWS.config.update(changes);
    if (!process.env.AWS_ENDPOINT_URL) {
      process.env.AWS_ENDPOINT_URL = endpoint;
    }
    this.simulithActivated = true;
    this.preserveProfileForSession = process.env.AWS_PROFILE === 'simulith';
  }

  isActive() {
    const cfg = this.getConfig();
    const stages = cfg.stages || ['dev', 'local'];
    if (!stages.includes(this.getStage())) {
      return false;
    }
    if (process.env.SIMULITH === '1' || process.env.SIMULITH === 'true') {
      return true;
    }
    if (this.simulithActivated) {
      return true;
    }
    if (process.env.AWS_PROFILE === 'simulith') {
      return true;
    }
    if (process.env.AWS_ENDPOINT_URL) {
      return true;
    }
    return false;
  }

  getEndpoint() {
    const cfg = this.getConfig();
    return (
      process.env.AWS_ENDPOINT_URL ||
      cfg.endpoint ||
      DEFAULT_ENDPOINT
    );
  }

  getAwsProvider() {
    const provider = this.serverless.getProvider('aws');
    if (!provider) {
      throw new Error('serverless-simulith requires provider.name aws');
    }
    return provider;
  }

  log(msg) {
    this.serverless.cli.log(`serverless-simulith: ${msg}`);
  }

  /** Simulith-specific deploy defaults — no per-project overlay yml required. */
  applySimulithDefaults() {
    if (!this.isActive()) {
      return;
    }

    const service = this.serverless.service;
    service.provider = service.provider || {};
    const simulithAccount = '000000000000';

    if (service.custom?.config?.ACCOUNT_ID) {
      service.custom.config.ACCOUNT_ID = simulithAccount;
    }
    if (service.custom?.ACCOUNT_ID) {
      service.custom.ACCOUNT_ID = simulithAccount;
    }

    if (!service.provider.deploymentMethod) {
      service.provider.deploymentMethod = 'direct';
    }
    delete service.provider.logRetentionInDays;

    if (service.functions) {
      for (const fn of Object.values(service.functions)) {
        if (fn && fn.disableLogs !== false) {
          fn.disableLogs = true;
        }
        if (Array.isArray(fn?.layers)) {
          fn.layers = fn.layers.map((layer) => {
            if (typeof layer === 'string') {
              return layer.replace(
                /arn:aws:lambda:[^:]+:\d+:layer:/,
                `arn:aws:lambda:${service.provider.region || 'us-east-1'}:${simulithAccount}:layer:`,
              );
            }
            return layer;
          });
        }
      }
    }

    if (service.custom?.authorizer?.users?.arn) {
      service.custom.authorizer.users.arn =
        service.custom.authorizer.users.arn.replace(
          /arn:aws:lambda:[^:]+:\d+:function:/,
          `arn:aws:lambda:${service.provider.region || 'us-east-1'}:${simulithAccount}:function:`,
        );
    }

    const skipPlugins = [
      'serverless-domain-manager',
      'serverless-add-api-key',
    ];
    if (Array.isArray(service.plugins)) {
      service.plugins = service.plugins.filter((entry) => {
        const name =
          typeof entry === 'string'
            ? entry
            : entry?.name || entry?.localPath || '';
        return !skipPlugins.some((skip) => name.includes(skip));
      });
    }

    this.defaultsApplied = true;
  }

  patchDeployState() {
    const deploy = this.findPlugin('AwsDeploy');
    if (deploy) {
      deploy.state = deploy.state || {};
    }
  }

  findPlugin(name) {
    return this.serverless.pluginManager.plugins.find(
      (p) => p.constructor.name === name,
    );
  }

  ensureConfigured() {
    if (!this.isActive()) {
      if (!this.skippedLogged) {
        this.log(
          `skipped (set AWS_PROFILE=simulith or AWS_ENDPOINT_URL for stage "${this.getStage()}")`,
        );
        this.skippedLogged = true;
      }
      return;
    }
    this.patchProviderRequest();
    if (this.configured) {
      return;
    }
    this.reconfigureEndpoints();
    this.configured = true;
  }

  patchProviderRequest() {
    if (this.providerRequestPatched) {
      return;
    }
    const awsProvider = this.getAwsProvider();
    this.awsProviderRequest = awsProvider.request.bind(awsProvider);
    awsProvider.request = this.interceptRequest.bind(this);
    this.providerRequestPatched = true;
  }

  async interceptRequest(service, method, params) {
    this.reconfigureEndpoints();

    if (process.env.SERVERLESS_SIMULITH_DEBUG) {
      this.log(`→ ${service}.${method}`);
    }

    if (method === 'validateTemplate') {
      this.log('skipping template validation (ValidateTemplate not on Simulith)');
      return '';
    }

    const svc = service.toLowerCase();
    if (svc === 'ecr') {
      if (method === 'describeRepositories') {
        this.log('skipping ECR DescribeRepositories (not on Simulith)');
        return { repositories: [] };
      }
      if (method === 'deleteRepository') {
        this.log('skipping ECR DeleteRepository (not on Simulith)');
        return {};
      }
    }

    const cfg = this.getAwsProvider().sdk.config;
    const svcKey = service.toLowerCase();
    if (cfg[svcKey] && params?.TemplateURL && cfg.s3?.endpoint) {
      params.TemplateURL = params.TemplateURL.replace(
        /https:\/\/s3\.amazonaws\.com/,
        cfg.s3.endpoint,
      );
    }

    return this.awsProviderRequest(service, method, params);
  }

  reconfigureEndpoints() {
    const endpoint = this.getEndpoint();
    const awsProvider = this.getAwsProvider();
    const changes = {};
    const cfg = this.getConfig();
    const preserveProfile =
      cfg.preserveProfileCredentials === true || this.preserveProfileForSession;

    const accessKeyId = process.env.AWS_ACCESS_KEY_ID || 'test';
    const secretAccessKey =
      process.env.AWS_SECRET_ACCESS_KEY || 'test';

    if (!preserveProfile) {
      changes.credentials = new AWS.Credentials({
        accessKeyId,
        secretAccessKey,
      });
      process.env.AWS_ACCESS_KEY_ID = accessKeyId;
      process.env.AWS_SECRET_ACCESS_KEY = secretAccessKey;
      awsProvider.cachedCredentials = null;
    } else {
      const existing = awsProvider.getCredentials();
      if (!existing.credentials) {
        changes.credentials = new AWS.Credentials({
          accessKeyId,
          secretAccessKey,
        });
        process.env.AWS_ACCESS_KEY_ID = accessKeyId;
        process.env.AWS_SECRET_ACCESS_KEY = secretAccessKey;
        awsProvider.cachedCredentials = null;
      }
    }

    if (changes.credentials) {
      awsProvider.getCredentials();
    }

    for (const service of AWS_SERVICES) {
      const entry = { endpoint };
      if (service === 's3') {
        entry.s3ForcePathStyle = true;
      }
      changes[service] = entry;
    }

    awsProvider.sdk.config.update(changes);
    AWS.config.update(changes);
    if (awsProvider.cachedCredentials) {
      awsProvider.cachedCredentials.endpoint = endpoint;
    }

    this.log(`reconfigured AWS SDK → ${endpoint}`);
  }
}

module.exports = ServerlessSimulithPlugin;
