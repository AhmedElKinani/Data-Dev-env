# Data-stack-dev-env

A generic, self-contained, and plug-and-play developer environment for Data Engineering and MLOps, running entirely on Docker Compose. 

```
[PySpark / SparkSQL] ──> [PostgreSQL] ──> [Apache Superset]
         │
         └──────────────> [ClearML MLOps Governance]
```

This stack provides a clean, idle developer workspace with PostgreSQL as the database, Jupyter Lab (pre-loaded with PySpark and ML libraries) as the workspace notebook, ClearML as the experiment tracker and governance server, and Apache Superset as the Business Intelligence dashboard. It comes pre-wired with configurations and connection drivers.

---

## Architecture & Components

*   **Jupyter Lab (`:8888`)**: Built on `jupyter/pyspark-notebook:latest`. Includes pre-installed packages: `findspark`, `clearml`, `scikit-learn`, `sqlalchemy`, and `psycopg2-binary`. Spark ML is also pre-installed.
*   **ClearML Server (`:8080` Web UI, `:8008` API, `:8081` Fileserver)**: Managed self-hosted architecture backed by MongoDB, Elasticsearch, and Redis. Pre-wired access credentials enable seamless SDK integration without manual UI setup.
*   **PostgreSQL (`:5432`)**: Serves two databases: `postgres` (the default blank database for developer tables/views) and `superset_db` (dedicated metadata store for Apache Superset).
*   **Apache Superset (`:8088`)**: Empty and clean slate dashboarding server configured with persistent PostgreSQL storage, ready to connect and build metrics.

---

## Prerequisites

| Requirement | Minimum Version | Notes |
| :--- | :--- | :--- |
| **Docker Desktop** | 4.x | Container environment |
| **RAM Allocated to Docker** | **12 GB** | ClearML Elasticsearch requires ~2 GB on its own. |
| **Disk Space** | 25 GB free | For pulling base docker images and volumes |

> [!IMPORTANT]
> **Docker Resource Allocations**: Ensure you configure Docker Desktop → Settings → Resources → Memory to at least **12 GB RAM**. Allocating fewer resources may lead to services failing to launch or crash loops.

---

## Quick Start

1.  **Clone / Navigate** into the directory:
    ```bash
    cd Data-stack-dev-env
    ```

2.  **Make setup script executable**:
    ```bash
    chmod +x setup.sh
    ```

3.  **Start and initialize the environment**:
    ```bash
    ./setup.sh
    ```

`setup.sh` will automatically create the scaffold directories, start the Docker container services, verify database health, wait for Superset initialization (db migrations and creation of the default admin user), and print connection URLs.

---

## Service Endpoints & Credentials

| Service | Endpoint | Connection Type / Credentials |
| :--- | :--- | :--- |
| **Jupyter Lab** | [http://localhost:8888](http://localhost:8888) | Tokenless auto-login |
| **ClearML Web UI** | [http://localhost:8080](http://localhost:8080) | Username: `developer` / Password: `developerpass` |
| **Apache Superset** | [http://localhost:8088](http://localhost:8088) | Admin User: `admin` / Password: `admin` |
| **PostgreSQL** | `localhost:5432` | User: `postgres` / Password: `postgres` / DB: `postgres` |

---

## Connection Configurations

### Jupyter / PySpark to PostgreSQL
The PostgreSQL JDBC driver (`postgresql-42.7.3.jar`) is pre-mounted in the Jupyter container at `/home/jovyan/jars/`. 

To connect PySpark to PostgreSQL:
```python
from pyspark.sql import SparkSession

spark = SparkSession.builder \
    .appName("MySparkApp") \
    .config("spark.jars", "/home/jovyan/jars/postgresql-42.7.3.jar") \
    .getOrCreate()

# Read from database
df = spark.read.jdbc(
    url="jdbc:postgresql://postgres:5432/postgres",
    table="my_table",
    properties={"user": "postgres", "password": "postgres", "driver": "org.postgresql.Driver"}
)
```

### ClearML Tracking in Jupyter
ClearML environment settings and credential tokens are pre-injected into the Jupyter container. You can immediately initialize experiment tracking in your notebooks:
```python
from clearml import Task

task = Task.init(
    project_name="MyDataStackProject",
    task_name="my_experiment",
    task_type=Task.TaskTypes.data_processing
)
```

---

## Verification & Playbook Demo

To verify that your environment is fully functional and integrated, a comprehensive playbook and cheatsheet notebook has been provided:

1.  Open **Jupyter Lab** at [http://localhost:8888](http://localhost:8888).
2.  Open `notebooks/spark_clearml_playbook.ipynb`.
3.  Click **Run All Cells** in the notebook (the entire notebook executes successfully using a built-in generic mock dataset and connections).
4.  The playbook demonstrates and executes:
    *   **Spark & SQL Setup**: Starting `findspark` and initializing `SparkSession` with the PostgreSQL JDBC driver jar.
    *   **PostgreSQL JDBC Read/Write**: Connecting to PostgreSQL, writing a test dataset, and reading it back to verify the database adapter works.
    *   **ClearML Governance**: Initializing a task, registering outputs manually with `OutputModel` (tagging, mapping labels, logging design metrics, and publishing to make them read-only), connecting an `InputModel` to track parent-child lineage, querying the registry programmatically, and tracking datasets version control using `Dataset`.
    *   **Data Engineering & ETL**: Loading CSVs, printing schema, dropping duplicates, dropping null values, renaming columns, type casting, grouping, sorting, filtering, and writing Parquet format.
    *   **SparkSQL Queries**: Registering temporary in-memory views and executing standard SQL queries.
    *   **Spark MLlib Preprocessing**: Syntax for `VectorAssembler`, `StandardScaler`, `MinMaxScaler`, `StringIndexer`, `OneHotEncoder`, and `VectorIndexer`.
    *   **Spark MLlib Supervised Learning**: Syntax for regression (`LinearRegression`, `GeneralizedLinearRegression`, `DecisionTreeRegressor`, `RandomForestRegressor`, `GBTRegressor`) and classification (`LogisticRegression`, `DecisionTreeClassifier`, `RandomForestClassifier`, `GBTClassifier`, `LinearSVC`, `NaiveBayes`).
    *   **Spark MLlib Unsupervised Learning**: Syntax for clustering (`KMeans`, `BisectingKMeans`, `GaussianMixture`, `LDA`) and dimensionality reduction (`PCA`).
    *   **Spark MLlib Neural Networks**: Syntax for `MultilayerPerceptronClassifier` (defining layer layout, block sizes, and solvers).
    *   **Spark Pipeline Execution**: Building, splitting, fitting, and transforming models.
    *   **MLlib Evaluators**: Evaluators for regression, binary classification, multiclass classification, and clustering metrics.
    *   **Model Persistence**: Saving and loading PySpark `PipelineModel` objects to and from disk.
5.  **Verify Results**:
    *   Open **ClearML UI** ([http://localhost:8080](http://localhost:8080)), navigate to Projects, and verify that the `DataStackPlaybook` project has captured the run metrics, hyperparameters, and the registered/published output model.
    *   Open a terminal and query PostgreSQL to verify the `jdbc_connection_test` table has been written.

---

## Managing the Stack

*   **Check running containers**:
    ```bash
    docker compose ps
    ```
*   **Inspect logs**:
    ```bash
    docker compose logs -f <service_name>
    ```
*   **Stop and tear down services** (preserves persistent volumes):
    ```bash
    docker compose down
    ```
*   **Wipe all data and start fresh**:
    ```bash
    docker compose down -v
    ```
