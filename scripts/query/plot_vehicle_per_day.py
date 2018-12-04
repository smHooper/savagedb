
import pandas as pd
import numpy as np
import pyodbc
import matplotlib.pyplot as plt
import seaborn as sns

path = "C:\Users\shooper\proj\savagedb\db\savage_frontend.accdb"
conn = pyodbc.connect(r'DRIVER={Microsoft Access Driver (*.mdb, *.accdb)};'
                      r'DBQ=%s' % db_path)
cursor = conn.cursor()
df = pd.read_sql('SELECT * FROM qry_vehicle_count_by_day', conn)

df['date'] = pd.to_datetime(df['obs_date'], format='%d-%b-%y')
label_inds = df.index[df.date.day == 20 & df.date.month == 5]
labels = df.loc[label_inds, 'date'].dt.year
plt.plot(np.arange(len(df)), df.vehicle_count)
plt.xticks(label_inds, labels)
sns.despine()
plt.show()