# Snappy
Database migration tool

## What can it do?
* Create a migration stub with specified name
* Execute not applied migrations
* Rollback all or to specific migration

## What features are yet not implemented?
* Squashing migrations. What it means is: execute all not applied migrations, dump structure, 
clean up migration info from database and from migrations folder
* Delayed migrations

## What is there?

This tool consists of three scripts related to migration process:
* create.sh
* migrate.sh
* rollback.sh

And two related to testing:
* test-adapter.sh
* test-compatibility.sh

## create.sh

### Purpose:
Creates named migration

### Usage:
		ADAPTER=<adapter_name> ./create.sh
		echo <migration_name> | ADAPTER=<adapter_name> ./create.sh

### Variables:
* ADAPTER - specifies name of the adapter to use **(required)**
* MIGRATION_DIR - specifies directory for creating migrations **(optional)**. Defaults to ./migrations

### Options: 
* --help - prints help
* -v, --version - prints out script version 
* --debug - set -x which will cause script to output what is executed 

### Arguments:
 none

### Result:
Creates directory in `MIGRATION_DIR` with following name template `yyymmddHHMMSS_<migration_name>`.
This directory will contain two files `up.sh` and `down.sh` for migration up and down respectively.

## migrate.sh

### Purpose:
Migrates all not applied migrations

### Usage:
		ADAPTER=<adapter_name> ./migrate.sh <options> 
 
### Variables:

* ADAPTER - specifies name of the adapter to use **(required)**
* MIGRATION_DIR - specifies directory for creating migrations **(optional)**. Defaults to ./migrations

### Options: 
* --help - prints help
* -v, --version - prints out script version
* --dry-run - Output what will be executed without actual execution
* --debug - set -x which will cause script to output what is executed 

Other options and what is required depends on adapter used. Please refer to `ADAPTER=<adapter_name> ./migrate.sh --help` for more information

### Arguments:
none

### Result:
Creates storage for applied migrations in database if not exists. Finds out diff between migrations in folder `MIGRATION_DIR` and migrations in migration storage inside db and then executes `up.sh` from that diff. 

## rollback.sh

### Purpose:
Rolling back all applied migrations or to specific applied migration.

### Usage:
		ADAPTER=<adapter_name> ./rollback <options> <migration_id>

### Variables:
* ADAPTER - specifies name of the adapter to use **(required)**
* MIGRATION_DIR - specifies directory for creating migrations **(optional)**. Defaults to ./migrations

### Options: 
* --help - prints help
* -v, --version - prints out script version
* --dry-run - Output what will be executed without actual execution
* --debug - set -x which will cause script to output what is executed
 
Other options and what is required depends on adapter used. Please refer to `ADAPTER=<adapter_name> ./rollback.sh --help` for more information

### Arguments:
Id of migration to rollback to (not inclusive) or 0 in order to rollback all

### Result:
Finds which migrations need to be rolled back from migration storage in database. Then calls `down.sh` for every such migration. 

## test-adapter.sh

### Purpose:
Runs tests for specified adapter against requested database

### Usage:
		ADAPTER=<adapter_name> ./test-adapter.sh <options>

### Variables:
* ADAPTER - specifies name of the adapter to use **(required)**

### Options:
* --help - prints help
* -v, --version - prints out script version
* --debug - set -x which will cause script to output what is executed

Other options and what is required depends on adapter used. Please refer to `ADAPTER=<adapter_name> ./test-adapter.sh --help` for more information

### Arguments:
none

### Result:
Finds adapter tests and executes them one by one. Prints out status of the test executed.

## test-compatibility.sh

### Purpose:
Runs all adapter tests in their specified environments ensuring compatibility

### Usage:
		./test-compatibility.sh <processes>

### Variables:
none

### Options:
none

### Arguments:
number of processes to use. **default: num_cores/2+1**

### Result:
Executes all adapter tests in specified environments. Prints test results for environments

## Wow cool, so how can I write some tests?

### Testing adapter
* Create folder `<adapter_name>` inside `tests` folder in the root of your project.
* Create folders: **create, migrate, rollback** inside `<adapter_folder>`
* Put tests inside create, migrate, rollback folders and make sure to make them executable.

### Testing compatibility
* Add os base dockerfile into `docker/app/<os_name>/<os_version>/<adapter>-dockerfile`. Ex. docker/app/alpine/3.8/mysql-dockerfile 
* Add db dockerfile into `docker/db/<db_name>/<db_version>-dockerfile`. Ex. docker/db/mysql/5.6.39-dockerfile. Database dockerfile **MUST** include **healthcheck** in order for tests to determine if database is ready
* You can repeat previous steps as many times as many different os and databases you want to tests your adapter against
* Add `connArgs.sh` to `tests/<adapter>` folder specifying how to connect to database
* Database will be chosen by default as adapter name. If you want to add more databases you can add `allowedDbs.txt` file to `tests/<adapter>` folder. Every database name should be delimited by new line.
