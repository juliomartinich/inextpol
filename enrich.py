# coding: utf-8
# inicio pruebas de cargar directo un excel y cambiar los nombres de variables acá
# 2024-oct-13 lógica para cambiar el returnRun como estado, y dejar en rsdn el ticket original
#             perfecciono la columna estado
#         -14 agrego un campo etapa a partir de un archivo excel etapasS.xls
import numpy as py
import pandas as pd

# leo todos los archivos, la primera columna trae el indice que se exportó, lo renombro como ID
log = pd.read_csv("logconsolidado.csv", delimiter=";", low_memory=False, index_col=0)
log.reset_index(inplace=True)
log.rename(columns={'index': 'ID'}, inplace=True)

log['rtruck'] = ''
license_to_truck = {}

print("-------------------------------------------")
print("1. completo rtruck a partir de licensePlate")
for i in range(len(log)):
    # obtengo los valores de la fila actual
    license_plate = log.at[i, 'licensePlate']
    truck_id = log.at[i, 'truckId']
    log.at[i, 'rtruck'] = truck_id
    if pd.notna(license_plate) and license_plate != "":            # si existe el valor
       if pd.notna(truck_id) and truck_id != "":              # si viene un valor, lo guardo en el diccionario
           license_to_truck[license_plate] = truck_id
       elif license_plate in license_to_truck:
           log.at[i, 'rtruck'] = license_to_truck[license_plate]

# 2da pasada
print(" 2da pasada")
for i in range(len(log)):
    # obtengo los valores de la fila actual
    license_plate = log.at[i, 'licensePlate']
    truck_id = log.at[i, 'truckId']
    r_truck = log.at[i,'rtruck']
    if ( pd.notna(license_plate) and license_plate in license_to_truck ) and ( pd.isna(r_truck) or r_truck == "" ):
        log.at[i, 'rtruck'] = license_to_truck[license_plate]
        
# diccionario syncrotessDeliveryNumber a rtruck
# todo lo que venga con sdn y no tenga rtruck, le pongo el rtruck de la lista que se construye a partir de telcli assignment
print("2. lleno rtruck a partir del valor de assignment")
sdn_to_rtruck = {}
for i in range(len(log)):
    rtruck   = log.at[i, 'rtruck']
    sdn      = log.at[i, 'syncrotessDeliveryNumber']
    if sdn != "SignOff" and pd.notna(sdn) and sdn != "":
        if log.at[i,'log'] == 'STo' and log.at[i, 'api'] == '/webservices/telematics/assignment':
            sdn_to_rtruck[sdn] = rtruck
        elif log.at[i,'log'] == 'STi' and log.at[i, 'api'] == '/webservices/telematics/deliveryState' and ( pd.isna(rtruck) or rtruck == "" ) and sdn in sdn_to_rtruck:
            log.at[i, 'rtruck'] = sdn_to_rtruck[sdn]
    
# diccionario truckId a syncrotessDeliveryNumber
truck_to_sdn = {}
log['rsdn'] = ''
# diccionarios rsdn a erpTicketNumber y truck
rsdn_to_ticket = {}
rsdn_to_truck  = {}
log['rticket'] = ''
print("3. lleno rsdn con syncrotes delivery number de la asignación")
for i in range(len(log)):
    truck_id = log.at[i, 'truckId']
    sdn      = log.at[i, 'syncrotessDeliveryNumber']
    log.at[i, 'rsdn'] = sdn
    if log.at[i,'log'] == 'SEo' and log.at[i, 'api'] == '/webservices/erp/delivery/assignment':
       # a partir de aca el camion tiene el syncrotessDeliveryNumber y la orderNo hasta que cambie
       truck_to_sdn[truck_id] = sdn
       rsdn_to_truck[sdn] = truck_id
       log.at[i,'rsdn'] = sdn
    # pongo en la columna rsdn el valor almacenado de ese camion (el camion está asignado a ese sdn)
    # si es que el camion tiene valor, y el sdn esta vacio
    if pd.notna(truck_id) and pd.isna(sdn) and truck_id in truck_to_sdn:
       log.at[i, 'rsdn'] = truck_to_sdn[truck_id]
    # si en la fila tengo rsdn, y no tengo truck, lo lleno (si tengo el valor de sdn en rsdn_to_truck
    rsdn = log.at[i, 'rsdn']
    r_truck = log.at[i, 'rtruck']
    if pd.notna(rsdn) and pd.isna(r_truck) and rsdn in rsdn_to_truck:
       log.at[i, 'rtruck'] = rsdn_to_truck[rsdn]

# si el syncrotessDeliveryNumber termina en returnRun, pongo RR en assignment y delivery, y limpio de _returnRun el sdn en rsdn
print("4. si el delivery number termina en _returnRun pongo sufijo RR al assignment y al delivery")
for i in range(len(log)):
    sdn      = log.at[i, 'syncrotessDeliveryNumber']
    apisola  = log.at[i, 'apisola']
    if pd.notna(sdn):
      if sdn.endswith('_returnRun'):
        log.at[i, 'apisola'] = apisola + "RR"
        log.at[i, 'rsdn'] = sdn[:-len('_returnRun')]

# Concatenar apisola y status, agregando un espacio antes del status si no es NaN
log['estado'] = ( log['log'].fillna('')
                + log['apisola'].apply(lambda x: f"-{x}" if pd.notna(x) else '') 
                + log['status'].apply(lambda x: f"-{x}" if pd.notna(x) else '') 
                + log['statusSource'].apply(lambda x: f"-{x}" if pd.notna(x) else '') 
                + log['deliveryType'].apply(lambda x: f"-{x}" if pd.notna(x) else '')
                + log['httpstatus'].str[:3].apply(lambda x: f"-{x}" if pd.notna(x) else '')
                )

# agrego el campo etapa
print("5. pongo las etapas del archivo de etapas")
etapas = pd.read_excel("etapas.xls")
# Realizar el join entre logord y etapas usando las columnas log, apisola, status y deliveryType
log_merged = pd.merge(log, etapas[['log', 'apisola', 'status', 'deliveryType', 'etapa','orden']],
                         on=['log', 'apisola', 'status', 'deliveryType'],
                         how='left')  # 'left' mantiene todas las filas de logord

columns_to_move = ['ID', 'log','fechahora','orden','S','F','T','etapa','estado','rtruck','truckId','SIGU','orderNo','erpTicketNumber','orderSubType','rsdn','syncrotessDeliveryNumber','shipPoint','locationID','deliveryQuantity','reuseQuantity','reasonCode','nrofunc','licensePlate','metodo','api','apisola','httpstatus','status','statusSource', 'deliveryType','detail']
remaining_columns = [col for col in log.columns if col not in columns_to_move]
new_column_order = columns_to_move + remaining_columns

logord = log_merged[new_column_order]

# rtruck decimal point is comma
print("cambio punto decimal por coma en rtruck")
logord['rtruck'] = logord['rtruck'].apply(lambda x: x.replace('.', ',') if isinstance(x, str) and x else x)


print("el resultado queda en logenrich.csv")
print("-------------------------------------------")
logord.to_csv("logenrich.csv", sep=";", decimal=",", header=True, na_rep="", index=False)

