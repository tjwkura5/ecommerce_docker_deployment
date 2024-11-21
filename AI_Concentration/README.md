# Fraud Detection in E-Commerce Transactions: A DevOps Team's Approach to ML Integration

## Business Scenario

The e-commerce DevOps team is exploring the implementation of a machine learning model to provide automatic insights into identifying fraudulent transactions on the platform. With an increasing number of transactions, detecting anomalies manually has become inefficient. The team is considering three models for anomaly detection:

- **Isolation Forests**: A tree-based model that isolates anomalies efficiently.
- **Clustering with DBSCAN**: A density-based clustering approach that identifies regions of high density and isolates points in sparse regions as anomalies.
- **Autoencoders**: Neural networks designed to reconstruct input data, where anomalies result in higher reconstruction errors.

The goal is to evaluate these models, compare their performance, and decide on the most effective approach to integrate into the application.  

## Instructions

### Steps to Complete

**Deploy the Application**  
   1. Create a t3.medium EC2 called "Model_server" in the public subnet of your custom vpc.
   2. Install Python3.9 on your server.
   3. Clone the repo to your server
   4. Navigate to the AI_Concentration directory and create a virtual environment
      ```
      python -m venv myenv
      ```
   5. Activate the virtual envrionment
      ```
      source myenv/bin/activate
      ```
   6. Install the Python librariers used by the models.
      ```
      pip install --upgrade pip
      pip install scikit-learn numpy pandas

      ```

### Connect to the Database

   In all of the model files fetch the data from your sqlite database into a data frame by adding the following to the top of your files.

   ```
   conn = sqlite3.connect('db.sqlite3')
   data = pd.read_sql_query("SELECT * FROM account_stripemodel", conn)
   conn.close()
   ```

### Run and Observe the Models  
   - Execute each of the three ML models (Isolation Forests, DBSCAN, Autoencoders) to identify anomalies in the transactions.  
   - Analyze the initial outputs:
     - **Isolation Forest**: [Identified 150 anomalies](AI_Concentration/anomalies_forests.csv).
     - **DBSCAN**: [Identified 2 anomalies](AI_Concentration/anomalies_cluster.csv).
     - **Autoencoder**: [Identified 30 anomalies](AI_Concentration/anomalies_auto.csv).   
 
### Select One Model

After evaluating fixing and tweaking all the models, I carefully inspected the anomalies each model identified. Here's why I ultimately chose DBSCAN as the best fit for this workload:

1. **Isolation Forest:** This model flagged too many records as anomalies. Upon reviewing the data, none of these records seemed indicative of fraud, which suggests the model was overly sensitive, producing a high number of false positives.

2. **Autoencoder:** While this model was more selective than the Isolation Forest, the records it flagged also did not exhibit characteristics that seemed fraudulent or unusual. This indicates that the reconstruction error threshold might not align well with the patterns of fraudulent activity in the dataset.

3. **DBSCAN:** Initially, I was hesitant about DBSCAN because it identified only two anomalies, which seemed too few compared to the other models. However, upon closer examination, the anomalies identified by DBSCAN appeared genuinely suspicious:

   * One record had missing customer information, a strong indicator of incomplete or suspicious data.
   * The other record was a transaction from India, while all other transactions occurred in the US. This geographic outlier stood out as unusual. 

### Tune the Model
  
  **eps:** The maximum distance between two samples for one to be considered as part of the other’s neighborhood. We can think of this as how close marbles need to be to call them "neighbors." If two marbles are within this distance, they might belong to the same group. A small eps means only very close marbles can be neighbors, so you'll have lots of small, tight groups. A big eps means marbles farther apart can still be in the same group.
  
  **min_samples:** The minimum number of data points required to form a dense region. Lower values make the model more sensitive to outliers. This would be like the number of marbles needed to say, "Hey, this is a proper group." If you set it low, even a tiny bunch of marbles can count as a group. If it's high, you need a bigger pile of marbles to make a group.

  The way to tune this model was try different combinations of eps and min_samples. I achieved this by using a nested for loop:

```
import sqlite3
import pandas as pd
from sklearn.cluster import DBSCAN
from sklearn.preprocessing import StandardScaler, LabelEncoder

# Load data from the database
conn = sqlite3.connect('db.sqlite3')
data = pd.read_sql_query("SELECT * FROM account_stripemodel", conn)
conn.close()

# Feature Engineering
data['email_domain'] = data['email'].apply(lambda x: x.split('@')[-1])
data['card_user_count'] = data.groupby('card_number')['user_id'].transform('count')
data['customer_id_count'] = data.groupby('customer_id')['user_id'].transform('count')

# Label Encoding for categorical variables
label_encoder = LabelEncoder()
data['address_country'] = label_encoder.fit_transform(data['address_country'])
data['address_state'] = label_encoder.fit_transform(data['address_state'])
data['email_domain'] = label_encoder.fit_transform(data['email_domain'])

# Define features and target variable
features = ['card_user_count', 'customer_id_count', 'address_country', 'address_state', 'exp_month', 'exp_year']
X = data[features]

# Standardize features for clustering
scaler = StandardScaler()
X_scaled = scaler.fit_transform(X)

# Parameters to tune
eps_values = [0.3, 0.5, 0.7, 1.0]
min_samples_values = [3, 5, 10]

pd.set_option('display.max_rows', None)  # Show all rows
pd.set_option('display.max_columns', None)  # Show all columns

# Loop over parameter combinations
for eps in eps_values:
    for min_samples in min_samples_values:
        dbscan = DBSCAN(eps=eps, min_samples=min_samples)
        clusters = dbscan.fit_predict(X_scaled)
        
        # Mark outliers as potential fraud (noise points are labeled -1 by DBSCAN)
        data['is_fraud'] = (clusters == -1).astype(int)
        
        # Extract fraud cases
        fraud_cases = data[data['is_fraud'] == 1]
        
        # Print summary and fraud records
        print(f"Parameters: eps={eps}, min_samples={min_samples}")
        print(f"Number of anomalies detected: {len(fraud_cases)}")
        print(fraud_cases)
        print("-" * 50)  # Separator for readability
  ```

## Test on New Data

   Most of the combinations from the preceding step identified the same two records from the original model except two.
   
   ```
   Parameters: eps=0.3, min_samples=3
   Number of anomalies detected: 42
   ```

   ```
   Parameters: eps=0.3, min_samples=5
   Number of anomalies detected: 91
   ```

I inspected the records and I decided to test different combinations on the unseen data as well. 

```
import sqlite3
import pandas as pd
from sklearn.cluster import DBSCAN
from sklearn.preprocessing import StandardScaler, LabelEncoder

# Load data from the database
data = pd.read_csv('account_stripemodel_fraud_data.csv')

# Feature Engineering
data['email_domain'] = data['email'].apply(lambda x: x.split('@')[-1])
data['card_user_count'] = data.groupby('card_number')['user_id'].transform('count')
data['customer_id_count'] = data.groupby('customer_id')['user_id'].transform('count')

# Label Encoding for categorical variables
label_encoder = LabelEncoder()
data['address_country'] = label_encoder.fit_transform(data['address_country'])
data['address_state'] = label_encoder.fit_transform(data['address_state'])
data['email_domain'] = label_encoder.fit_transform(data['email_domain'])

# Define features and target variable
features = ['card_user_count', 'customer_id_count', 'address_country', 'address_state', 'exp_month', 'exp_year']
X = data[features]

# Standardize features for clustering
scaler = StandardScaler()
X_scaled = scaler.fit_transform(X)

# Parameters to tune
eps_values = [0.3, 0.5, 0.7, 1.0]
min_samples_values = [3, 5, 10]

# Loop over parameter combinations
for eps in eps_values:
    for min_samples in min_samples_values:
        dbscan = DBSCAN(eps=eps, min_samples=min_samples)
        clusters = dbscan.fit_predict(X_scaled)
        
        # Mark outliers as potential fraud (noise points are labeled -1 by DBSCAN)
        data['is_fraud'] = (clusters == -1).astype(int)
        
        # Extract fraud cases
        fraud_cases = data[data['is_fraud'] == 1]
        
        # Print summary and fraud records
        print(f"Parameters: eps={eps}, min_samples={min_samples}")
        print(f"Number of anomalies detected: {len(fraud_cases)}")
        print(fraud_cases)
        print("-" * 50)
```

### Results

Using the DBSCAN model with `eps=0.7` and `min_samples=5`, the algorithm identified **58 anomalies**. Upon reviewing the flagged records, a clear pattern of duplicate card usage by certain customers emerged. Many anomalies involved the same card being associated with multiple user IDs under a single customer ID, which is unusual behavior and could indicate shared, compromised, or fraudulent card usage.

### Integration into Application UI

To seamlessly incorporate the DBSCAN model into the e-commerce platform's application UI, the following architecture and workflow are proposed:

1. **Deploying the Model Server in a Private Subnet**  
   To enhance security, the model server should be moved to a **private subnet** within the VPC. This ensures that the server is isolated from public access while still accessible from other services within the VPC (e.g., database or application servers). 

2. **Automating Model Execution**  
   The DBSCAN model can be scheduled to run at predefined intervals using a **cron job** or triggered by specific events. For example:
   - **Cron Job:** The model could execute daily, weekly, or hourly, depending on the volume of transactions and the business's fraud detection needs.
   - **Event-Driven Trigger:** The model could be triggered when a threshold number of new transactions are inserted into the database. This can be implemented using AWS Lambda or similar event-driven services connected to the database.

3. **Storing Results in the Database**  
   After each model execution, the flagged anomalies (potential fraudulent transactions) should be stored in a **dedicated fraud table** in the database. This table would include:
   - Transaction details
   - Anomaly score or confidence level
   - Timestamp of when the transaction was flagged
   - Any additional metadata generated by the model (e.g., cluster ID).

4. **Admin Dashboard for Fraud Monitoring**  
   The flagged transactions can then be displayed in an **admin dashboard** in the UI. This dashboard could include:
   - A list view of flagged transactions with sortable columns (e.g., card number, user ID, customer ID, timestamp).
   - A detailed view for each flagged transaction, providing full transaction details and model insights.
   - Filtering options to allow admins to view anomalies based on transaction date, card number, or anomaly type.
   - An export feature to download flagged transactions as a CSV for further offline analysis.

5. **Real-Time Alerts for High-Risk Cases**  
   To handle urgent or high-risk cases, the system could integrate with an alerting mechanism to notify administrators. For instance:
   - **Email Alerts:** Notify admins when a high-confidence anomaly is detected.
   - **UI Notifications:** Provide a real-time alert within the admin dashboard.
