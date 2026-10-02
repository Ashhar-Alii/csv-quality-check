{% macro save_test_results() %}
  {% if execute %}
    
    {# 1. Create the target table if it does not exist #}
    {% set create_sql %}
      CREATE TABLE IF NOT EXISTS {{ target.catalog }}.{{ target.schema }}.dbt_test_results (
        run_started_at TIMESTAMP, 
        invocation_id STRING,
        test_name STRING, 
        status STRING, 
        failures BIGINT
      )
    {% endset %}
    {% do run_query(create_sql) %}
    
    {# 2. Collect and filter out test rows #}
    {% set test_rows = [] %}
    {% for result in results %}
      {% if result.node is defined and result.node.resource_type == 'test' %}
        {% set failures = result.failures if result.failures is not none else 0 %}
        {# Escape single quotes in test names to prevent SQL syntax breakage #}
        {% set clean_test_name = result.node.name | replace("'", "''") %}
        
        {% set row_value = "(TIMESTAMP '" ~ run_started_at ~ "', '" ~ invocation_id ~ "', '" ~ clean_test_name ~ "', '" ~ result.status ~ "', " ~ failures ~ ")" %}
        {% do test_rows.append(row_value) %}
      {% endif %}
    {% endfor %}
    
    {# 3. If tests exist, insert them all at once in a single database roundtrip #}
    {% if test_rows | length > 0 %}
      {% set insert_sql %}
        INSERT INTO {{ target.catalog }}.{{ target.schema }}.dbt_test_results
        VALUES {{ test_rows | join(', ') }}
      {% endset %}
      {% do run_query(insert_sql) %}
    {% endif %}

  {% endif %}
{% endmacro %}
