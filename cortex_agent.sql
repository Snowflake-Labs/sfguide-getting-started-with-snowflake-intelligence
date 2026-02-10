USE ROLE ACCOUNTADMIN;

CREATE DATABASE IF NOT EXISTS SNOWFLAKE_INTELLIGENCE;
CREATE SCHEMA IF NOT EXISTS SNOWFLAKE_INTELLIGENCE.AGENTS;

USE DATABASE SNOWFLAKE_INTELLIGENCE;
USE SCHEMA AGENTS;

CREATE OR REPLACE AGENT Sales_AI
    COMMENT = 'Sales and marketing AI agent for analyzing sales data and customer support'
    PROFILE = '{"display_name": "Sales//AI", "color": "blue"}'
    FROM SPECIFICATION
    $$
    models:
        orchestration: claude-4-sonnet

    orchestration:
        budget:
            seconds: 60
            tokens: 16000

    instructions:
        system: "You are a helpful sales and marketing assistant that helps users analyze sales data, marketing campaigns, and customer support information."
        orchestration: "Whenever you can answer visually with a chart, always choose to generate a chart even if the user didn't specify to."
        sample_questions:
            - question: "Show me the trend of sales by product category between June and August"
            - question: "What issues are reported with jackets recently in customer support tickets?"
            - question: "Why did sales of Fitness Wear grow so much in July?"

    tools:
        - tool_spec:
            type: "cortex_analyst_text_to_sql"
            name: "SalesAnalyst"
            description: "Analyzes sales and marketing data using the semantic model"
        - tool_spec:
            type: "cortex_search"
            name: "SupportSearch"
            description: "Searches customer support cases and transcripts"
        - tool_spec:
            type: "procedure"
            name: "Send_Email"

    tool_resources:
        SalesAnalyst:
            semantic_view: "DASH_DB_SI.RETAIL.SALES_AND_MARKETING_DATA"
        SupportSearch:
            name: "DASH_DB_SI.RETAIL.SUPPORT_CASES"
            max_results: "10"
        Send_Email:
            procedure: "DASH_DB_SI.RETAIL.SEND_EMAIL()"
            execution_environment:
                type: "warehouse"
                warehouse: "DASH_WH_SI"
            argument_descriptions:
                body: "Use HTML-Syntax for this. If the content you get is in markdown, translate it to HTML. If body is not provided, summarize the last question and use that as content for the email."
                recipient_email: "If the email is not provided, send it to the current user's email address."
                subject: "If the subject is not provided, use 'Snowflake Intelligence'."
    $$;

CREATE SNOWFLAKE INTELLIGENCE IF NOT EXISTS SNOWFLAKE_INTELLIGENCE_OBJECT_DEFAULT;

ALTER SNOWFLAKE INTELLIGENCE SNOWFLAKE_INTELLIGENCE_OBJECT_DEFAULT ADD AGENT SNOWFLAKE_INTELLIGENCE.AGENTS.Sales_AI;

GRANT USAGE ON SNOWFLAKE INTELLIGENCE SNOWFLAKE_INTELLIGENCE_OBJECT_DEFAULT TO ROLE SNOWFLAKE_INTELLIGENCE_ADMIN;

GRANT USAGE ON AGENT SNOWFLAKE_INTELLIGENCE.AGENTS.Sales_AI TO ROLE SNOWFLAKE_INTELLIGENCE_ADMIN;
