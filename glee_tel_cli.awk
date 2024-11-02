# Julio Martinich 1-oct-2024
# glee_tel_cli.awk lee los archivos log telematic Client
# v1  2-oct-24 basado en el lector de erp server
#
# awk -f glee_tel_cli.awk {archivo log} > tel_cli.csv      --- deja el resultado en tel_cli.csv
#
# en mi mac uso gawk y funciona
# GNU Awk 5.3.1, API 4.0, PMA Avon 8-g1, (GNU MPFR 4.2.1, GNU MP 6.3.0)
#
# el bloque BEGIN se ejecuta una sola vez, lo uso para poner los titulos, con ; para que sea un archivo csv leible en excel
BEGIN { 
    print "log;fechahora;mseg;tipo;tiponum;metodo;api;apisola;httpstatus;host;msgId;version;timeStamp;subOrgID;requestID;licensePlate;syncrotessDeliveryNumber;syncrotessDeliveryNumberCancel;orderSubType;locationID;reasonCode;radius;latitude;longitude;erpTicketNumber";
}
#
# este bloque se ejecuta para cada línea de entrada, $0 es la línea completa, $1, $2, ... son los tokens separados por espacio
{   
    # Extracción de algunos campos directamente por su ubicacion en el archivo
    # las ubicaciones las vi directamente inspeccionando el archivo

    # hay lineas que vienen con ctrl-M, las limpio
    linea = $0;
    gsub(//,"",linea)

    # solo me intreresan los tipos de registro 99 == RequestLog
    if ( match(linea, /99 == RequestLog/ )) {
        tiponum = 99;
        fecha = $1;
        hora = $2;
        # en la hora sustituyo el . por ; para que en el CSV quede separado en hora y milisegundos
        gsub(/\./, ";", hora);
        fechahora = fecha " " hora ;
        tipo = $8;
        numero = $10;

        # Extrae la parte después de "99 == RequestLog"
        result = substr(linea, RSTART + RLENGTH);
        # Divide el resultado en tokens separados por espacios
        split(result, tokens, " ");
        metodo = tokens[1];
        api = tokens[2];
        # el metodo viene escrito HttpRequest[POST
        if (match(linea, /HttpRequest\[([A-Z]+)/, resultado)) {
            metodo= resultado[1];
        }

        # la api comienza con /webservices/telematics/...
        if (match(api, /\/webservices\/telematics\/([^"]+)/, resultado )) {
            apisola = resultado[1];
        }
        # la funcion match la uso sobre $0 que es la linea leida completa
        # el resultado de lo encontrado en la expresion regular queda en un array 
        # para cada exoresion en parentesis redondos () hay un resultado 
        # el primer dato del array es el que tiene el primer resultado (en este caso uno solo)
        # voy obteniendo los datos del string uno por uno
    
        # host en minusculas expresion regular de una IP y puerto
        if (match(linea, /Host[[:space:]]*:[[:space:]]*([0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}:[0-9]+)/, resultado)) {
            host= resultado[1];
        } else { host= ""; }

        # msgId (lo que está entre comillas y que no sea comillas)
        if (match(linea, /"msgId":"([^"]+)"/, resultado)) {
            msgId = resultado[1];
        } else { msgId = ""; }
    
        # sttVersion (lo que está entre comillas y que no sea comillas)
        if (match(linea, /"sttVersion":"([^"]+)"/, resultado)) {
            sttVersion = resultado[1];
        } else { sttVersion = ""; }
    
        # timeStamp (lo que está entre comillas y que no sea comillas)
        if (match(linea, /"timeStamp":"([^"]+)"/, resultado)) {
            timeStamp = resultado[1];
        } else { timeStamp = ""; }
    
        # subOrgID (lo que está entre comillas y que no sea comillas)
        if (match(linea, /"subOrgID":"([^"]+)"/, resultado)) {
            subOrgID = resultado[1];
        } else { subOrgID = ""; }
    
        # requestID (lo que está entre comillas y que no sea comillas)
        if (match(linea, /"requestID":"([^"]+)"/, resultado)) {
            requestID = resultado[1];
        } else { requestID = ""; }
    
        # vehicleNumber (lo que está entre comillas y que no sea comillas)
        # lo pongo como licensePlate porque así esta en otras partes
        if (match(linea, /"vehicleNumber":"([^"]+)"/, resultado)) {
            vehicleNumber = resultado[1];
        } else { vehicleNumber = ""; }
    
        # orderSubType (lo que está entre comillas y que no sea comillas)
        if (match(linea, /"orderSubType":"([^"]+)"/, resultado)) {
            orderSubType = resultado[1];
        } else { orderSubType = ""; }
    
        # LocationID (lo que está entre comillas y que no sea comillas)
        if (match(linea, /"locationID":"([^"]+)"/, resultado)) {
            locationID = resultado[1];
        } else { locationID = ""; }
    
        # reasonCode (lo que está entre comillas y que no sea comillas)
        if (match(linea, /"reasonCode":"([^"]+)"/, resultado)) {
            reasonCode = resultado[1];
        } else { reasonCode = ""; }
    
        # syncrotessDeliveryNumber en cancel (lo que está entre comillas y que no sea comillas)
        if (match(linea, /"syncrotessDeliveryNumber":\["([^"]+)"\]/, resultado)) {
            syncrotessDeliveryNumberCancel= resultado[1];
        } else { syncrotessDeliveryNumberCancel= ""; }
    
        # syncrotessDeliveryNumber en assignment (lo que está entre comillas y que no sea comillas)
        if (match(linea, /"syncrotessDeliveryNumber":"([^"]+)"/, resultado)) {
            syncrotessDeliveryNumber= resultado[1];
        } else { syncrotessDeliveryNumber= ""; }

        if ( syncrotessDeliveryNumber == "" ) {
            syncrotessDeliveryNumber = syncrotessDeliveryNumberCancel;
        }

        # erpTicketNumer en assignment (lo que está entre comillas y que no sea comillas)
        if (match(linea, /"erpTicketNumber":"([^"]+)"/, resultado)) {
            erpTicketNumber= resultado[1];
        } else { erpTicketNumber= ""; }

        # unloadingLocation
        if (match(linea, /"unloadingLocation":\{(.*)\}/, resultado)) {
            unloadingLocation= resultado[1];
            if (match(unloadingLocation, /"radius":([0-9]+)/, resultado)) {
                radius=resultado[1];
            } else { radius = ""}
            if (match(unloadingLocation, /"latitude":(-?[0-9]+\.[0-9]+)/, resultado)) {
                latitude=resultado[1];
                gsub(/\./, ",", latitude)
            } else { latitude = ""}
            if (match(unloadingLocation, /"longitude":(-?[0-9]+\.[0-9]+)/, resultado)) {
                longitude=resultado[1];
                gsub(/\./, ",", longitude)
            } else { longitude = ""}
        } else { unloadingLocation= ""; }
       


    
       # me quedo con las variables guardadas y voy a la siguiente linea, que debe ser la respuesta
        next;
    }


    if ( match(linea, /159 ==/ )) {
        result = substr(linea, RSTART + RLENGTH);
        if (match(result, /HTTP\/1\.1 ([0-9]+) ([A-Za-z ]+)/, resultado)) {
            status = resultado[1];
            respuesta = resultado[2];
            httpstatus = status " " respuesta;
        } else { httpstatus = ""; }

        # imprimo en una linea todos los datos separados por ; para que funcione como archivo csv
        print "STo;" fechahora ";" tipo ";" tiponum ";" metodo ";" api ";" apisola ";" httpstatus ";" host ";" msgId ";" sttVersion ";" timeStamp ";" subOrgID ";" requestID ";" vehicleNumber ";" syncrotessDeliveryNumber ";" syncrotessDeliveryNumberCancel ";" orderSubType ";" locationID ";" reasonCode ";" radius ";" latitude ";" longitude ";" erpTicketNumber ;
    }

}
