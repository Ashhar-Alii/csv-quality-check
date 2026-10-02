# csv_quality_gate

A minimal dbt project implementing Write-Audit-Publish: a landed CSV is
typed and tested in `stg_orders`, and `orders` (the production mart) only
gets built if every test on `stg_orders` passes. This is what the Kestra
blueprint's `databricks.job.CreateJob` task runs as a native Databricks
dbt job task.

## Setup

1. **Push this folder to a GitHub repo** (public is simplest for testing --
   private works too if your Databricks workspace's Git integration has
   access to it).

2. **Edit `dbt_project.yml`** -- change `vars.landing_volume_path` to match
   the actual Unity Catalog Volume path you created
   (`/Volumes/<catalog>/<schema>/<volume_name>`). This must match the `to:`
   path in the Kestra flow's `databricks.dbfs.Upload` task exactly.

3. **In the Kestra YAML**, point the dbt job task's `gitSource` at this
   repo's URL and branch, and make sure `catalog` / `schema` in the
   `dbtTask` block match a schema your Databricks user can write to.

4. **Test both branches** using the two sample CSVs:
   - `sample_data/good_orders.csv` -- passes every test, `orders` builds,
     Slack should report success (or stay silent, depending on how you
     wire the pass branch).
   - `sample_data/bad_orders.csv` -- has a duplicate `order_id` (fails
     `unique`), a blank `order_id` (fails `not_null`), and an
     `unknown_status` value (fails `accepted_values`). `orders` should
     show as **SKIPPED** in the Databricks run, and the Slack alert should
     fire with the failed test names.

   Upload whichever one you're testing to the landing volume path (either
   manually via the Databricks UI, or by running the Kestra flow with that
   file as the input), then trigger the flow.

## Notes

- `dbt deps` is included in the job commands for convenience but is a
  no-op here -- there's no `packages.yml`, so nothing to install. Add one
  if you later want packages like `dbt_utils`.
- No `profiles.yml` is committed on purpose -- Databricks' native dbt job
  task builds the connection profile for you from the `warehouseId`,
  `catalog`, and `schema` set on the job task itself.
- `orders` is `incremental` with a `merge` strategy keyed on `order_id`,
  so re-running with overlapping data updates existing rows rather than
  duplicating them.
