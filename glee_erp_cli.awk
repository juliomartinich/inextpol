# Julio Martinich 2-oct-2024
# glee_erp_cli.awk lee los archivos log erp Client
# v1  2-oct-24 basado en el lector de tel client
#
# awk -f glee_erp_cli.awk {archivo log} > erp_cli.csv      --- deja el resultado en erp_cli.csv
#
# en mi mac uso gawk y funciona
# GNU Awk 5.3.1, API 4.0, PMA Avon 8-g1, (GNU MPFR 4.2.1, GNU MP 6.3.0)
#
# el bloque BEGIN se ejecuta una sola vez, lo uso para poner los titulos, con ; para que sea un archivo csv leible en excel
BEGIN { 
    print "log;fechahora;mseg;tipo;tiponum;host;metodo;api;apisola;httpstatus;correlationId;clientCurrentTime;version;orderNo;itemNo;syncrotessDeliveryNumber;shipPoint;truckId;deliveryQuantity;reuseQuantity;dispatchGroup;truckName;reasonCode;cancelReason";
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
        fechahora = fecha " " hora;
        tipo = $8;
        numero = $10;
        #
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

        # la api comienza con /webservices/erp/delivery/...
        if (match(api, /\/webservices\/erp\/delivery\/([^"]+)/, resultado )) {
            apisola = resultado[1];
        }
        # la funcion match la uso sobre $0 que es la linea leida completa
        # el resultado de lo encontrado en la expresion regular queda en un array 
        # para cada exoresion en parentesis redondos () hay un resultado 
        # el primer dato del array es el que tiene el primer resultado (en este caso uno solo)
        # voy obteniendo los datos del string uno por uno

        # Host con H mayuscula expresion regular de una IP
        if (match(linea, /Host[[:space:]]*:[[:space:]]*([0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}:[0-9]+)/, resultado)) {
            host= resultado[1];
        } else { host= ""; }
    
        # metadata
        # correlationId (lo que está entre comillas y que no sea comillas)
        if (match(linea, /"correlationId":"([^"]+)"/, resultado)) {
            correlationId = resultado[1];
        } else { correlationId = ""; }
    
        # clientCurrentTime (lo que está entre comillas y que no sea comillas)
        if (match(linea, /"clientCurrentTime":"([^"]+)"/, resultado)) {
            clientCurrentTime = resultado[1];
        } else { clientCurrentTime = ""; }
    
        # Version (lo que está entre comillas y que no sea comillas)
        if (match(linea, /"version":"([^"]+)"/, resultado)) {
            version = resultado[1];
        } else { version = ""; }
    
        # delivery
        # orderNo (lo que está entre comillas y que no sea comillas)
        if (match(linea, /"orderNo":"([^"]+)"/, resultado)) {
            orderNo = resultado[1];
        } else { orderNo = ""; }
    
        # itemNo (lo que está entre comillas y que no sea comillas)
        if (match(linea, /"itemNo":"([^"]+)"/, resultado)) {
            itemNo = resultado[1];
        } else { itemNo = ""; }
    
        # syncrotessDeliveryNumber (lo que está entre comillas y que no sea comillas)
        if (match(linea, /"syncrotessDeliveryNumber":"([^"]+)"/, resultado)) {
            syncrotessDeliveryNumber = resultado[1];
        } else { syncrotessDeliveryNumber = ""; }
    
        # shipPoint (lo que está entre comillas y que no sea comillas)
        if (match(linea, /"shipPoint":"([^"]+)"/, resultado)) {
            shipPoint = resultado[1];
        } else { shipPoint = ""; }
    
        # truckId (lo que está entre comillas y que no sea comillas)
        if (match(linea, /"truckId":"([^"]+)"/, resultado)) {
            truckId = resultado[1];
        } else { truckId = ""; }
    
        # dispatchGroup (lo que está entre comillas y que no sea comillas)
        if (match(linea, /"dispatchGroup":"([^"]+)"/, resultado)) {
            dispatchGroup = resultado[1];
        } else { dispatchGroup = ""; }
    
        # truckName (lo que está entre comillas y que no sea comillas)
        if (match(linea, /"truckName":"([^"]+)"/, resultado)) {
            truckName = resultado[1];
        } else { truckName = ""; }
    
        # deliveryQuantity (lo que está entre comillas y que no sea comillas)
        if (match(linea, /"deliveryQuantity":([0-9.]+)/, resultado)) {
            deliveryQuantity = resultado[1];
            gsub(/\./, ",", deliveryQuantity);
        } else { deliveryQuantity = ""; }
    
        # reuseQuantity (lo que está entre comillas y que no sea comillas)
        if (match(linea, /"reuseQuantity":([0-9.]+)/, resultado)) {
            reuseQuantity = resultado[1];
            gsub(/\./, ",", reuseQuantity);
        } else { reuseQuantity = ""; }
    
        # cancel
        # reasonCode (lo que está entre comillas y que no sea comillas)
        if (match(linea, /"reasonCode":"([^"]+)"/, resultado)) {
            reasonCode = resultado[1];
        } else { reasonCode = ""; }
    
        # cancelReason (lo que está entre comillas y que no sea comillas)
        if (match(linea, /"cancelReason":"([^"]+)"/, resultado)) {
            cancelReason = resultado[1];
        } else { cancelReason = ""; }

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
        print "SEo;" fechahora ";" tipo ";" tiponum ";" host ";" metodo ";" api ";" apisola ";" httpstatus ";" correlationId ";" clientCurrentTime ";" version ";" orderNo ";" itemNo ";" syncrotessDeliveryNumber ";" shipPoint ";" truckId ";" deliveryQuantity ";" reuseQuantity ";" dispatchGroup ";" truckName ";" reasonCode ";" cancelReason ;
    }

}
