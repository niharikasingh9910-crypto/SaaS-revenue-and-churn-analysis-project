import pandas as pd
import pyodbc
import seaborn as sns
import matplotlib.pyplot as plt

#To know sql server driver
print([x for x in pyodbc.drivers() if 'SQL Server' in x])

#credentials
server_name = '******************'
database = '**********'
username = '******'
password = '*********'
driver = '{ODBC Driver 18 for SQL Server}'


connection_string = (
    f'DRIVER={driver};'
    f'SERVER={server_name};'
    f'DATABASE={database};'
    f'UID={username};'
    f'PWD={password};'
    'Encrypt=yes;'
    'TrustServerCertificate=no;'
    'Connection Timeout= 30;'
)

#connecting to Azure using pyodbc
try:
    conn = pyodbc.connect(connection_string)
    query = "SELECT * FROM dbs.subscriptions;"
    df = pd.read_sql(query,conn)
    print("Success! Data Shape:" ,df.shape)
    conn.close()
except pyodbc.Error as e:
    print("Connection failed. Error details: \n",e)



#turning churned to numeric
df['churned_numeric'] = df['churned'].apply(lambda x:1 if x == 'Yes' else 0)
print(df['churned_numeric'])


numerical_colums = df[['support_tickets_12mo','nps_score','feature_usage_pct','churned_numeric']]

#calculating correlation
corr_matrix = numerical_colums.corr()
churned_corr = corr_matrix[['churned_numeric']]

#plotting the figure
plt.figure(figsize=(8,6))
sns.heatmap(churned_corr,annot=True,cmap='coolwarm',fmt='.2f')
plt.title("customer Behaviour and Churn correlation heatmap")
plt.show()
