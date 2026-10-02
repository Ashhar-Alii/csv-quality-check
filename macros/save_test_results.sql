{% macro save_test_results() %}
  {% if execute %}
    {% set create_sql %}
      CREATE TABLE IF NOT EXISTS {{ target.catalog }}.{{ target.schema }}.dbt_test_results (
        run_started_at TIMESTAMP, invocation_id STRING,
        test_name STRING, status STRING, failures BIGINT
      )
    {% endset %}
    {% do run_query(create_sql) %}
    {% for result in results %}
      {% if result.node is defined and result.node.resource_type == 'test' %}
        {% set failures = result.failures if result.failures is not none else 0 %}
        {% set insert_sql %}
          INSERT INTO {{ target.catalog }}.{{ target.schema }}.dbt_test_results
          VALUES (
            TIMESTAMP '{{ run_started_at }}', '{{ invocation_id }}',
            '{{ result.node.name }}', '{{ result.status }}', {{ failures }}
          )
        {% endset %}
        {% do run_query(insert_sql) %}
      {% endif %}
    {% endfor %}
  {% endif %}
{% endmacro %}
