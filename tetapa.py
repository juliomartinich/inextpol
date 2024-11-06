# coding: utf-8
# inicio pruebas de cargar directo un excel y cambiar los nombres de variables acá
# 2024-oct-13 lógica para cambiar el returnRun como estado, y dejar en rsdn el ticket original
#             perfecciono la columna estado
#         -14 agrego un campo etapa a partir de un archivo excel etapasS.xls
import numpy as np
import pandas as pd

# funcion para formatear hh:mm:ss las diferencias de tiempo
def format_timedelta(td):
    if isinstance(td, pd.Timedelta) and td != pd.Timedelta(0):
        total_seconds = int(td.total_seconds())
        hours, remainder = divmod(total_seconds, 3600)
        minutes, seconds = divmod(remainder, 60)
        return f"{hours:02}:{minutes:02}:{seconds:02}"
    return ""  # Si es NaT o cero

print("-------------------------------------------")
print("leo logenrichif.csv")
# la primera columna trae el indice que se exportó, lo renombro como ID
log = pd.read_csv("logenrichf.csv", delimiter=";", low_memory=False, index_col=0)
log.reset_index(inplace=True)
log.rename(columns={'index': 'ID'}, inplace=True)

# Ordenar el DataFrame según las columnas especificadas
log = log.sort_values(by=['rtruck', 'fechahora', 'etapa', 'orden'])

# Crear la columna 'tetapa' con valores de 'fechahora' cuando 'orden' es 1, y NaN en los demás casos
log['tetapa'] = log['fechahora'].where(log['orden'] == 1)

# Rellenar hacia adelante para propagar el valor de 'fechahora' hasta el próximo 1
log['tetapa'] = log['tetapa'].ffill()

log['fechahora'] = pd.to_datetime(log['fechahora'])
log['tetapa'] = pd.to_datetime(log['tetapa'])

# Asegúrate de que la columna 'tetapa' ya esté rellenada correctamente
log['dif2'] = np.where(log['orden'] == 1, log['tetapa'], log['fechahora'] - log['tetapa'])
log['dif2'] = pd.to_datetime(log['dif2'])

log['difetapa'] = log['tetapa'] - log['tetapa'].shift(1)

# Crear la columna 'trans' con las condiciones dadas
log['trans'] = np.where(
    (log['orden'] == 1) &
    (log['difetapa'] < pd.Timedelta(seconds=30)) &
    (log['difetapa'] != pd.Timedelta(0)) &
    (log['difetapa'].notna()) &
    (log['etapa'].str[:2].isin(["07", "08", "09", "10"])),
    "corto",
    ""
)
log['difetapa'] = log['difetapa'].apply(format_timedelta)

# Añadir la columna 'dif3' con las condiciones dadas
log['dif3'] = np.where(
    (log['orden'] == 1) & (log['etapa'].isin(["01A.LOGIN", "02.ASIG", "12A.LOGOUT"])),
    log['tetapa'].dt.strftime('%Y-%m-%d %H:%M:%S'),
    log['difetapa']
)

log['detailsn'] = log['detail'].str.replace(r'\d+', 'XX', regex=True)

columns_to_move = ['rtruck','etapa','orden','fechahora','tetapa','dif2','difetapa','dif3','trans','estado','rsdn','truckId','erpTicketNumber','orderSubType','syncrotessDeliveryNumber','detailsn','shipPoint','locationID','deliveryQuantity','reuseQuantity','reasonCode','nrofunc','licensePlate','metodo','api','apisola','httpstatus','status','statusSource', 'deliveryType']
remaining_columns = [col for col in log.columns if col not in columns_to_move]
new_column_order = columns_to_move + remaining_columns
    
logord = log[new_column_order]

print("el resultado queda en logetapa.csv")
print("-------------------------------------------")
logord.to_csv("logetapa.csv", sep=";", decimal=",", header=True, na_rep="", index=False)

logord1 = logord[logord['orden'] == 1]
logord1['etapanum'] = logord1['etapa'].str[:2].astype(int)

columns_to_move = ['rtruck','etapa','etapanum','orden','fechahora','tetapa','dif2','difetapa','dif3','trans','estado','rsdn','truckId','erpTicketNumber','orderSubType','syncrotessDeliveryNumber','detailsn','shipPoint','locationID','deliveryQuantity','reuseQuantity','reasonCode','nrofunc','licensePlate','metodo','api','apisola','httpstatus','status','statusSource', 'deliveryType']
remaining_columns = [col for col in log.columns if col not in columns_to_move]
new_column_order = columns_to_move + remaining_columns

logord2 = logord1[new_column_order]

print("el resultado queda en logetapa1.csv")
print("-------------------------------------------")
logord2.to_csv("logetapa1.csv", sep=";", decimal=",", header=True, na_rep="", index=False)

# Define el rango de interés
etapas_interes = set(range(5, 11))

# Función para verificar etapas
def verificar_etapas(grupo):
    etapas_presentes = set(grupo['etapanum']).intersection(etapas_interes)
    if etapas_interes - etapas_presentes:
        return 'falta'
    else:
        return 'bueno'

# Aplica la verificación para cada combinación de rtruck y rsdn
resultados_faltas = (
    logord1.groupby(['rtruck', 'rsdn'])
    .apply(verificar_etapas)
    .reset_index(name='faltas')
)

resultados_cortos = (
    logord1.groupby(['rtruck', 'rsdn'])['trans']
    .apply(lambda x: 'malo' if 'corto' in x.values else 'bueno')
    .reset_index(name='cortos')
)

resultados_combinados = resultados_faltas.merge(
    resultados_cortos,
    on=['rtruck', 'rsdn'],
    how='outer'  # Puedes usar 'inner' si solo deseas las coincidencias
)

resultados_cancel = (
    logord1.groupby(['rtruck', 'rsdn'])['etapanum']
    .apply(lambda x: 'cancelado' if 11 in x.values else 'nocancel')
    .reset_index(name='cancelados')
)

resultados_combinados2 = resultados_combinados.merge(
    resultados_cancel,
    on=['rtruck', 'rsdn'],
    how='outer'  # Puedes usar 'inner' si solo deseas las coincidencias
)

# Muestra el resultado
print("el resultado queda en malosbuenos.csv")
print("-------------------------------------------")
resultados_combinados2.to_csv("malosbuenos.csv", sep=";", decimal=",", header=True, na_rep="", index=False)



