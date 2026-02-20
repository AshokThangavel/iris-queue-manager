# %ZQueue Management System

A robust, process-based queue manager designed for asynchronous task execution. This system ensures high availability by decoupling task submission from processing.

## 🚀 Overview
The system utilizes a producer-consumer architecture to manage background jobs. It is designed to handle high-volume entries with built-in persistence, ensuring that no data is lost even if the process is interrupted.

Here’s the corrected version with clearer wording and formatting:


> **Note:**
>
> 1. Click the **Start Queue** button in the Angular application.
> 2. Ensure Docker is running and connect to **InterSystems IRIS**.
> 3. Start an IRIS session:
>
> ```bash
> iris session iris
> ```
>
> 4. Once connected (and Docker is up), start the queue:
>
> ```objectscript
> Write ##class(%ZQueue.Manager).Start()
> ```



### Key Features
* **Persistence:** Data survives system or process restarts.
* **Traceability:** Every job is linked to a specific Process ID for monitoring.
* **Efficiency:** Offloads heavy tasks to keep the main application responsive.


## 🛠 Usage

Use the following methods to control the lifecycle of the queue background process.
## ⚙️ Installation

### Clone the Repository
```bash
git clone https://github.com/AshokThangavel/iris-queue-manager.git
cd iris-queue-manager
````

### Running the Application with Docker

Build and start the app using Docker Compose:

```bash
docker-compose up --build
```

### Stopping the Application

To stop and remove the running containers:

```bash
docker-compose down
```
In your **README.md**, the "Usage" section explains how a developer actually interacts with the project once the Docker containers are running.

Here is a clear breakdown you can use to explain these two endpoints:


### 🖥️ Usage & Access Points

Once the project is started, you can access the different layers of the application via these URLs:

#### **1. Frontend Interface (Angular)**

* **URL:** [http://localhost:8080](http://localhost:8080/)
* **What it is:** This is the user-facing dashboard.

#### **2. Backend Management (InterSystems IRIS)**

* **URL:** [http://localhost:52773/csp/sys/UtilHome.csp](http://localhost:52773/csp/sys/UtilHome.csp)
* **What it is:** The **Management Portal** for the InterSystems IRIS database.
  
### Start the Queue
To initiate the background worker and begin processing entries, run:

```objectscript
Write ##class(%ZQueue.Manager).Start()

```

* **Output:** This returns the **Process ID (PID)** of the newly created background job.
* **Behavior:** Once started, the manager will immediately begin processing any pending entries in the queue.

### Check Queue is running

```objectscript
Write ##class(%ZQueue.Manager).IsQueueRunning()
```

### Stop the Queue

To gracefully shut down the background worker, run:

```objectscript
Write ##class(%ZQueue.Manager).Stop()

```


* **Behavior:** This command stops the active queue process.
* **Important Note:** Stopping the process **does not delete** the entries in the queue.
* **Resuming:** Once you call the `.Start()` method again, the manager will resume processing the existing entries from where it left off.

---

Here’s the corrected and polished version:

## 📊 Screen Workflow Logic

1. **New Task:** The task is validated and stored in the queue.
2. **Active Queue:** View the current queue details.
3. **History:** Upon successful execution, the task is marked as complete and moved to History.
4. **Dead Letter:** Upon execution failure, the task is moved to the Dead Letter queue.

<img width="1890" height="1002" alt="image" src="https://github.com/user-attachments/assets/82d2eeb7-e801-46ab-b53d-af2f059307e5" />


