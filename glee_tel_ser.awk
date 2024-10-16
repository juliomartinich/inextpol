# Julio Martinich
# lee archivos log de syncrotess de telemetria Server
# 29-sep-2024 primera version
#  1-oct      le cambio el nombre y leo todo el archivo sin necesidad de primero hacer grep body
# 
# para correr este script primero se debe hacer 
# chmod +x glee_tel_ser.awk
#
# awk -f glee_tel_ser.awk {archivo log tel server} > tel_ser.csv
#
# en mi mac uso gawk y funciona
# GNU Awk 5.3.1, API 4.0, PMA Avon 8-g1, (GNU MPFR 4.2.1, GNU MP 6.3.0)
#
# el bloque BEGIN se ejecuta una sola vez, lo uso para poner los titulos, con ; para que sea un archivo csv leible en excel
BEGIN { print "log;fechahora;mseg;tipo;numero;tiponum;metodo;host;host2;api;apisola;version;httpstatus;timeStamp;subOrgID;licensePlate;syncrotessDeliveryNumber;status;statusSource;latitude;longitude;eta;productAmount;leftOverAmount;mess"; }
#
# este bloque se ejecuta para cada línea de entrada, $0 es la línea completa, $1, $2, ... son los tokens separados por espacio
{   
    # Extracción de algunos campos directamente por su ubicacion en el archivo
    # las ubicaciones las vi directamente inspeccionando el archivo
    linea = $0;
    gsub(/^M/,"",linea)

    # solamente me interesan los mensaje 111 (recepcion) y 116 (respuesta)
    if ( match(linea, /111 ==/ )) {
        tiponum = 111;
        fecha = $1;
        hora = $2;
        # en la hora sustituyo el . por ; para que en el CSV quede separado en hora y milisegundos
        gsub(/\./, ";", hora);
        fechahora = fecha " " hora;
        tipo = $8;
        numero = $10;
        # Extrae la parte después de "111 =="
        result = substr(linea, RSTART + RLENGTH);
        # Divide el resultado en tokens separados por espacios
        split(result, tokens, " ");
        reqresp = tokens[1];
        metodo  = tokens[2];
        api     = tokens[3];
        if (match(api, /telematics\/([^\/]+)/, resultado)) {
            apisola = resultado[1];
        } else { apisola = ""; }

        IP = $23;
        # la funcion match la uso sobre $0 que es la linea leida completa
        # el resultado de lo encontrado en la expresion regular queda en un array 
        # para cada exoresion en parentesis redondos () hay un resultado 
        # el primer dato del array es el que tiene el primer resultado (en este caso uno solo)
        # voy obteniendo los datos del string uno por uno
    
        # Busca syncrotessDeliveryNumber
        # expresion regular: obtenga lo que esté entre comillas, y que no sea comillas
        if (match($0, /"syncrotessDeliveryNumber":"([^"]+)"/, resultado)) {
            stn = resultado[1];
        } else { stn = ""; }
    
        # Host con H mayuscula expresion regular de una IP
        if (match($0, /Host: ([0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3})/, resultado)) {
            host = resultado[1];
        } else { host = ""; }
    
        # host en minusculas expresion regular de una IP y puerto
        if (match($0, /host: ([0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}:[0-9]+)/, resultado)) {
            host2 = resultado[1];
        } else { host2 = ""; }

        # sttVersion (lo que está entre comillas y que no sea comillas)
        if (match($0, /"sttVersion":"([^"]+)"/, resultado)) {
            ver = resultado[1];
        } else { ver = ""; }
    
        # timeStamp (lo que está entre comillas y que no sea comillas)
        if (match($0, /"timeStamp":"([^"]+)"/, resultado)) {
            ts = resultado[1];
        } else { ts = ""; }
    
        # subOrgID (lo que está entre comillas y que no sea comillas)
        if (match($0, /"subOrgID":"([^"]+)"/, resultado)) {
            soi = resultado[1];
        } else { soi = ""; }
    
        # Busca vehicleNumber (misma expresion regular)
        if (match($0, /"vehicleNumber":"([^"]+)"/, resultado)) {
            vn = resultado[1];
        } else { vn = ""; }
    
        # Busca status (idem)
        if (match($0, /"status":"([^"]+)"/, resultado)) {
            st = resultado[1];
        } else { st = ""; }
    
        # Busca statusSource (idem)
        if (match($0, /"statusSource":"([^"]+)"/, resultado)) {
            sts = resultado[1];
        } else { sts = ""; }
    
        # Busca mensaje (idem)
        if (match($0, /"messageText":"([^"]+)"/, resultado)) {
            mess = resultado[1];
        } else { mess = ""; }
    
        # Busca eta (idem)
        if (match($0, /"eta":"([^"]+)"/, resultado)) {
            eta = resultado[1];
        } else { eta = ""; }
    
        # Busca productQuantityActual
        # expresion regular lo que está entre {}
        # como {} son caracteres clave en las expresiones regulares, se pone backslash
        # adentro de los parentesis, obtenga todo lo que no sea }
        if (match($0, /"productQuantityActual":\{([^}]*)\}/, resultado)) {
            pqa = resultado[1];
            # ahora obtengo un número con punto decimal
            if (match(pqa, /"amount":([0-9]+\.[0-9]+)/, resultado)) {
                amount = resultado[1];
                # lo pongo con , para que se lea bien en excel
                gsub(/\./, ",", amount)
            } else {
                amount = "";
            }
        } else {
            pqa = "";
            amount = "";
        }
    
        # busca leftOver, similar a productQuantityActual
        if (match($0, /"leftOver":\{([^}]*)\}/, resultado)) {
            lo = resultado[1];
            # ahora obtengo un número con punto decimal
            if (match(lo, /"amount":([0-9]+\.[0-9]+)/, resultado)) {
                loamount = resultado[1];
                # lo pongo con , para que se lea bien en excel
                gsub(/\./, ",", loamount)
            } else {
                loamount = "";
            }
        } else {
            pqa = "";
            loamount = "";
        }
    
        # Busca latitude
        if (match($0, /"latitude":([^"]+),/, resultado)) {
            lat = resultado[1];
            # lo pongo con , para que se lea bien en excel
            gsub(/\./, ",", lat)
        } else { lat = ""; }
    
        # Busca longitude
        if (match($0, /"longitude":([^"]+),/, resultado)) {
            long = resultado[1];
            # lo pongo con , para que se lea bien en excel
            gsub(/\./, ",", long)
        } else { long = ""; }

        # me quedo con las variables guardadas y voy a la siguiente linea, que debe ser la respuesta
        next;
    }
    
    # ----- ahora leo la respuesta e imprimo
    if ( match(linea, /116 ==/ )) {
        # Extrae la parte después de "116 =="
        result = substr(linea, RSTART + RLENGTH);
        # Divide el resultado en tokens separados por espacios
        split(result, tokens, " ");
        cod_resp  = tokens[3];
        respuesta = tokens[4];
        httpstatus = cod_resp " " respuesta;
        # imprimo en una linea todos los datos separados por ; para que funcione como archivo csv
        print "STi;" fechahora ";" tipo ";" numero ";" tiponum ";" metodo ";" host ";" host2 ";" api ";" apisola ";" ver ";" httpstatus ";" ts ";" soi ";" vn ";" stn ";" st ";" sts ";" lat ";" long ";" eta ";" amount ";" loamount ";" mess;
    }

}
