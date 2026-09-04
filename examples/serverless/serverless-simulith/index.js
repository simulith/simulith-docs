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

    this.hooks = {
      initialize: () => this.ensureConfigured(),
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
      'dev'
    );
  }

  isActive() {
    const cfg = this.getConfig();
    const stages = cfg.stages || ['dev', 'local'];
    return stages.includes(this.getStage());
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
          `skipped (stage "${this.getStage()}" not in custom.simulith.stages)`,
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

    const existing = awsProvider.getCredentials();
    if (!existing.credentials) {
      const accessKeyId = process.env.AWS_ACCESS_KEY_ID || 'test';
      const secretAccessKey =
        process.env.AWS_SECRET_ACCESS_KEY || 'test';
      changes.credentials = new AWS.Credentials({
        accessKeyId,
        secretAccessKey,
      });
      process.env.AWS_ACCESS_KEY_ID = accessKeyId;
      process.env.AWS_SECRET_ACCESS_KEY = secretAccessKey;
      awsProvider.cachedCredentials = null;
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
