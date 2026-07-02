locals {
  # Same locals as original Loyaleasy module (Cloud Posse ssm-parameter-store).
  environment = var.env == "DEV" ? "dev" : lower(var.env)
  name_prefix = "${var.project_name}-${local.environment}"

  # Original hardcodes /LOYALEASY/${var.env}/; Simulith uses /SIMULITH/${var.env}/ when project_name=simulith
  ssm_prefix = "/${upper(var.project_name)}/${var.env}"

  database_secret      = var.use_remote_state ? data.terraform_remote_state.secrets[0].outputs.secret_name : var.database_secret_override
  vpc_id               = var.use_remote_state ? data.terraform_remote_state.subnets[0].outputs.vpc_id : var.vpc_id_override
  database_subnet_1_id = var.use_remote_state ? data.terraform_remote_state.subnets[0].outputs.database_subnet_1_id : var.database_subnet_ids_override[0]
  database_subnet_2_id = var.use_remote_state ? data.terraform_remote_state.subnets[0].outputs.database_subnet_2_id : var.database_subnet_ids_override[1]
  database_subnet_3_id = var.use_remote_state ? data.terraform_remote_state.subnets[0].outputs.database_subnet_3_id : var.database_subnet_ids_override[2]
  database_subnet_4_id = var.use_remote_state ? data.terraform_remote_state.subnets[0].outputs.database_subnet_4_id : var.database_subnet_ids_override[3]
  database_subnet_5_id = var.use_remote_state ? data.terraform_remote_state.subnets[0].outputs.database_subnet_5_id : var.database_subnet_ids_override[4]
  database_subnet_6_id = var.use_remote_state ? data.terraform_remote_state.subnets[0].outputs.database_subnet_6_id : var.database_subnet_ids_override[5]
  secrets_manager_sg   = var.use_remote_state ? data.terraform_remote_state.secrets[0].outputs.secrets_manager_sg : var.secrets_manager_sg_override
  rds_proxy_endpoint   = var.use_remote_state ? data.terraform_remote_state.proxydb[0].outputs.rds_proxy_endpoint : var.rds_proxy_endpoint_override
  rds_proxy_sg         = var.use_remote_state ? data.terraform_remote_state.proxydb[0].outputs.rds_proxy_sg : var.rds_proxy_sg_override
  cognito_user_pool_id = var.use_remote_state ? data.terraform_remote_state.cognito[0].outputs.user_pool_id : var.cognito_user_pool_id_override
  cognito_client_id    = var.use_remote_state ? data.terraform_remote_state.cognito[0].outputs.client_id : var.cognito_client_id_override
  ses_from_email       = var.use_remote_state ? data.terraform_remote_state.ses[0].outputs.from_email : var.ses_from_email_override
  ses_otp_template     = var.use_remote_state ? data.terraform_remote_state.ses[0].outputs.otp_template_name : var.ses_otp_template_name_override

  common_tags = {
    Environment = local.environment
    ManagedBy   = "terraform"
    Name        = "${local.name_prefix}-parameters"
    Project     = var.project_name
  }

  # Same parameter set and types as Cloud Posse module parameter_write block.
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
