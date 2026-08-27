locals {
  environment = var.env == "DEV" ? "dev" : lower(var.env)
  name_prefix = "${var.project_name}-${local.environment}"
  ssm_prefix  = "/${upper(var.project_name)}/${var.env}"

  database_secret      = data.terraform_remote_state.secrets.outputs.secret_name
  vpc_id               = data.terraform_remote_state.subnets.outputs.vpc_id
  database_subnet_1_id = data.terraform_remote_state.subnets.outputs.database_subnet_1_id
  database_subnet_2_id = data.terraform_remote_state.subnets.outputs.database_subnet_2_id
  database_subnet_3_id = data.terraform_remote_state.subnets.outputs.database_subnet_3_id
  database_subnet_4_id = data.terraform_remote_state.subnets.outputs.database_subnet_4_id
  database_subnet_5_id = data.terraform_remote_state.subnets.outputs.database_subnet_5_id
  database_subnet_6_id = data.terraform_remote_state.subnets.outputs.database_subnet_6_id
  secrets_manager_sg   = data.terraform_remote_state.secrets.outputs.secrets_manager_sg
  rds_proxy_endpoint   = data.terraform_remote_state.proxydb.outputs.rds_proxy_endpoint
  rds_proxy_sg         = data.terraform_remote_state.proxydb.outputs.rds_proxy_sg
  cognito_user_pool_id = data.terraform_remote_state.cognito.outputs.user_pool_id
  cognito_client_id    = data.terraform_remote_state.cognito.outputs.client_id
  ses_from_email       = data.terraform_remote_state.ses.outputs.from_email
  ses_otp_template     = data.terraform_remote_state.ses.outputs.otp_template_name

  common_tags = {
    Environment = local.environment
    ManagedBy   = "terraform"
    Name        = "${local.name_prefix}-parameters"
    Project     = var.project_name
  }

  parameter_defs = {
    ACCESS_KEY_ID         = { type = "SecureString", value = var.access_key_id }
    SECRET_ACCESS_KEY     = { type = "SecureString", value = var.secret_access_key }
    SECRET_PASSWORD       = { type = "SecureString", value = var.secret_password }
    DATABASE_SECRET       = { type = "SecureString", value = local.database_secret }
    ACCOUNT_ID            = { type = "String", value = var.account_id }
    ALGORITHM             = { type = "String", value = var.algorithm }
    API_KEY               = { type = "SecureString", value = var.api_key }
    DOMAIN                = { type = "String", value = var.domain }
    ENDPOINT              = { type = "String", value = var.endpoint }
    REGION                = { type = "String", value = var.region }
    VPC_ID                = { type = "String", value = local.vpc_id }
    DATABASE_SUBNET_1_ID  = { type = "String", value = local.database_subnet_1_id }
    DATABASE_SUBNET_2_ID  = { type = "String", value = local.database_subnet_2_id }
    DATABASE_SUBNET_3_ID  = { type = "String", value = local.database_subnet_3_id }
    DATABASE_SUBNET_4_ID  = { type = "String", value = local.database_subnet_4_id }
    DATABASE_SUBNET_5_ID  = { type = "String", value = local.database_subnet_5_id }
    DATABASE_SUBNET_6_ID  = { type = "String", value = local.database_subnet_6_id }
    SECRETS_MANAGER_SG    = { type = "String", value = local.secrets_manager_sg }
    RDS_PROXY_ENDPOINT    = { type = "String", value = local.rds_proxy_endpoint }
    RDS_PROXY_SG          = { type = "String", value = local.rds_proxy_sg }
    COGNITO_USER_POOL_ID  = { type = "String", value = local.cognito_user_pool_id }
    COGNITO_CLIENT_ID     = { type = "String", value = local.cognito_client_id }
    SES_FROM_EMAIL        = { type = "String", value = local.ses_from_email }
    SES_OTP_TEMPLATE_NAME = { type = "String", value = local.ses_otp_template }
    JWT_ISSUER            = { type = "String", value = var.jwt_issuer }
    JWT_AUDIENCE          = { type = "String", value = var.jwt_audience }
  }
}
