-- Summary of objects created in this script:
--
-- Roles:
--   - snowflake_intelligence_admin
--
-- Warehouses:
--   - WH_SI_JP
--
-- Databases:
--   - DB_SI_JP
--   - snowflake_intelligence
--
-- Schemas:
--   - DB_SI_JP.retail
--   - snowflake_intelligence.agents
--
-- File Format:
--   - swt_csvformat
--
-- Stages:
--   - swt_marketing_data_stage
--   - swt_products_data_stage
--   - swt_sales_data_stage
--   - swt_social_media_data_stage
--   - swt_support_data_stage
--   - semantic_models
--
-- Tables:
--   - marketing_campaign_metrics
--   - products
--   - sales
--   - social_media
--   - support_cases
--
-- Notification Integration:
--   - email_integration
--
-- Stored Procedure:
--   - send_email


USE ROLE accountadmin;

CREATE OR REPLACE ROLE snowflake_intelligence_admin;
GRANT CREATE WAREHOUSE on account to role snowflake_intelligence_admin;
GRANT CREATE DATABASE on account to role snowflake_intelligence_admin;
GRANT CREATE INTEGRATION on account to role snowflake_intelligence_admin;

SET current_user = (select current_user());   
GRANT ROLE snowflake_intelligence_admin to user identifier($current_user);
ALTER USER SET default_role = snowflake_intelligence_admin;
ALTER USER SET default_warehouse = WH_SI_JP;

USE ROLE snowflake_intelligence_admin;
CREATE OR REPLACE DATABASE DB_SI_JP;
USE DATABASE DB_SI_JP;
CREATE OR REPLACE SCHEMA RETAIL;
CREATE OR REPLACE WAREHOUSE WH_SI_JP WITH WAREHOUSE_SIZE = 'large';

CREATE DATABASE IF NOT EXISTS snowflake_intelligence;
CREATE SCHEMA IF NOT EXISTS snowflake_intelligence.agents;

GRANT CREATE AGENT on schema snowflake_intelligence.agents to role snowflake_intelligence_admin;

USE DATABASE DB_SI_JP;
USE SCHEMA RETAIL;
USE WAREHOUSE WH_SI_JP;

CREATE OR REPLACE file format swt_csvformat  
  skip_header = 1  
  field_optionally_enclosed_by = '"'  
  type = 'csv'
;  
  
-- create table marketing_campaign_metrics and load data from s3 bucket
CREATE OR REPLACE stage swt_marketing_data_stage  
  file_format = swt_csvformat  
  url = 's3://sfquickstarts/sfguide_getting_started_with_snowflake_intelligence_ja/marketing/';  
  
CREATE OR REPLACE table marketing_campaign_metrics (
  date date,
  category varchar(16777216),
  campaign_name varchar(16777216),
  impressions number(38,0),
  clicks number(38,0)
);

COPY INTO marketing_campaign_metrics  
  FROM @swt_marketing_data_stage;

-- create table products and load data from s3 bucket
CREATE OR REPLACE stage swt_products_data_stage  
  file_format = swt_csvformat  
  url = 's3://sfquickstarts/sfguide_getting_started_with_snowflake_intelligence_ja/product/';  
  
CREATE OR REPLACE table products (
  product_id number(38,0),
  product_name varchar(16777216),
  category varchar(16777216)
);

COPY INTO products  
  from @swt_products_data_stage;

-- create table sales and load data from s3 bucket
CREATE OR REPLACE stage swt_sales_data_stage  
  file_format = swt_csvformat  
  url = 's3://sfquickstarts/sfguide_getting_started_with_snowflake_intelligence_ja/sales/';  
  
CREATE OR REPLACE table sales (
  date date,
  region varchar(16777216),
  product_id number(38,0),
  units_sold number(38,0),
  sales_amount number(38,2)
);

COPY INTO sales  
  FROM @swt_sales_data_stage;

-- create table social_media and load data from s3 bucket
CREATE OR REPLACE stage swt_social_media_data_stage  
  file_format = swt_csvformat  
  url = 's3://sfquickstarts/sfguide_getting_started_with_snowflake_intelligence_ja/social_media/';  
  
CREATE OR REPLACE table social_media (
  date date,
  category varchar(16777216),
  platform varchar(16777216),
  influencer varchar(16777216),
  mentions number(38,0)
);

COPY INTO social_media  
  FROM @swt_social_media_data_stage;

-- create table support_cases and load data from s3 bucket
CREATE OR REPLACE stage swt_support_data_stage  
  file_format = swt_csvformat  
  url = 's3://sfquickstarts/sfguide_getting_started_with_snowflake_intelligence_ja/support/';  
  
CREATE OR REPLACE table support_cases (
  id varchar(16777216),
  title varchar(16777216),
  product varchar(16777216),
  transcript varchar(16777216),
  date date
);

COPY INTO support_cases  
  FROM @swt_support_data_stage
;

CREATE OR REPLACE stage semantic_models encryption = (type = 'snowflake_sse') directory = ( enable = true );

CREATE OR REPLACE notification integration email_integration
  type=email
  enabled=true
  default_subject = 'snowflake intelligence'
;

CREATE OR REPLACE PROCEDURE send_email(
    recipient_email varchar,
    subject varchar,
    body varchar
)
returns varchar
language python
runtime_version = '3.12'
packages = ('snowflake-snowpark-python')
handler = 'send_email'
as
$$
def send_email(session, recipient_email, subject, body):
    try:
        # Escape single quotes in the body
        escaped_body = body.replace("'", "''")
        
        # Execute the system procedure call
        session.sql(f"""
            CALL SYSTEM$SEND_EMAIL(
                'email_integration',
                '{recipient_email}',
                '{subject}',
                '{escaped_body}',
                'text/html'
            )
        """).collect()
        
        return "Email sent successfully"
    except Exception as e:
        return f"Error sending email: {str(e)}"
$$;

ALTER ACCOUNT SET CORTEX_ENABLED_CROSS_REGION = 'AWS_US';

SELECT 'Congratulations! Snowflake Intelligence セットアップは無事完了しました！' as status;
