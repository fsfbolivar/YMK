#!/usr/bin/env bash

##################################################
#
#  Copyright (C) 2017 - GBO Integradores S.A.S.
#  Todos los derechos reservados
#
##################################################


##################################################
#
#  Print on screen with a copy on log
#

LOG_FILE="${HOME}/logs/process-image.log"

Print () {
	echo "$@"
	echo "$@" >> "${LOG_FILE}"
}


#
##################################################


##################################################
#
#  Load API KEY
#

API_KEY_FILE="${HOME}/settings/YMK_API_KEY"

if test -f "${API_KEY_FILE}"
then
	Print "[ OK ] API Key loaded from setting file"
	YMK_API_KEY=$(cat "${API_KEY_FILE}")
else
	Print "[WARN] API Key defined with a default value"
	YMK_API_KEY="AIzaSyBvrxw4PZ5f-bagWONrqqWvewo3E1Jk0zM"
fi

#
##################################################


##################################################
#
#  Check arguments
#

if test "$#" -eq 1
then
	Print "[ OK ] The number of arguments seems to be fine"
else
	Print "[ERRO] Wrong number of arguments. Expected one, found $#"
	exit 1
fi

if test -f "$1"
then
	Print "[ OK ] input file: $1"
else
	Print "[ERRO] cannot find input file: $1"
	exit 1
fi

#
##################################################


##################################################
#
#  Calculate INPUT_FILE_PATH and INPUT_FILE_NAME
#

INPUT_FILE_PATH="$1"
INPUT_FILE_NAME=$(basename "${INPUT_FILE_PATH}")

#
##################################################


##################################################
#
#  Copy the file in our Google Bucket
#

if gsutil cp "${INPUT_FILE_PATH}" "gs://ymk/"
then
	Print "[ OK ] File copied into Google Bucket"
else
	Print "[ERRO] cannot copy the input file into Google Bucket"
	exit 1
fi

#
##################################################


##################################################
#
#  Make the file public
#

if gsutil acl ch -u AllUsers:R "gs://ymk/${INPUT_FILE_NAME}"
then
	Print "[ OK ] File is public now"
else
	Print "[ERRO] cannot make public the file"
	exit 1
fi

#
##################################################


##################################################
#
#  Compose the request.json as a tmp file
#

REQUEST_JSON=$(mktemp --suffix=.json)

cat > "${REQUEST_JSON}" <<EOF
{
  "requests": [
    {
      "image": {
        "source": {
          "gcsImageUri": "gs://ymk/${INPUT_FILE_NAME}"
        }
      },
      "features": [
        {
          "type": "TEXT_DETECTION"
        }
      ]
    }
  ]
}
EOF

if test "$?" -eq 0
then
	Print "[ OK ] Request.json created successfully"
else
	Print "[ERRO] Request.json with problems"
	exit 1
fi

Print "[INFO] Request.json is ${REQUEST_JSON}"

#
##################################################


##################################################
#
#  Google Vision Cloud API
#

RESPONSE_JSON=$(mktemp --suffix=.json)

curl -v -k -s -H "Content-Type: application/json" \
	https://vision.googleapis.com/v1/images:annotate?key=$YMK_API_KEY \
	--data-binary @${REQUEST_JSON} \
	> "${RESPONSE_JSON}"

if test "$?" -eq 0
then
	Print "[ OK ] Response.json created successfully"
else
	Print "[ERRO] Response.json with problems"
	exit 1
fi

Print "[INFO] Response.json is ${RESPONSE_JSON}"

#
##################################################


###################################################
##
##  Talend
##
#
#TALEND_JOB="$HOME/talend/ymk.sh"
#TALEND_INPUT=$(mktemp --suffix=.txt)
#echo -e $(jq '.responses[0].textAnnotations[0].description' "${RESPONSE_JSON}")  >  "${TALEND_INPUT}"
#if test "$?" -eq 0
#then
#	Print "[ OK ] Talend.txt created successfully"
#else
#	Print "[ERRO] Talend.txt with problems"
#	exit 1
#fi
#
#Print "[INFO] Talend.txt is ${TALEND_INPUT}"
#exit 0
#
#if "${TALEND_JOB}" --context_param path="${TALEND_INPUT}"
#then
#	Print "[ OK ] Talend job executed successfully"
#else
#	Print "[ERRO] Talend job executed with errors"
#	exit 1
#fi
#
##
###################################################


##################################################
#
#  Extraer los datos que nos interesan
#

SQL_FILE=$(mktemp --suffix=.sql)

echo -e $(jq '.responses[0].textAnnotations[0].description' "${RESPONSE_JSON}") | awk '
BEGIN {
    print "INSERT INTO DOC_DATA ("
    print "rif_emisor_end,"
    print "rif_emisor,"
    print "razon_social_emisor,"
    print "numero_control,"
    print "numero_factura,"
    print "fecha_factura,"
    print "razon_social_cliente,"
    print "rif_cliente,"
    print "codigo_marca_comercial,"
    print "numero_pedido,"
    print "fecha_pedido,"
    print "base_imponible,"
    print "iva_doc,"
    print "total_doc"
    print ") VALUES ("
}
END {
    print ") ; "
}
NR==1  {print "'\''" $0 "'\'', "}
NR==1  {print "'\''" $0 "'\'', "}
NR==2  {print "'\''" $0 "'\'', "}
NR==4  {print "'\''" $0 "'\'', "}
NR==10 {print "'\''" $0 "'\'', "}
NR==13 {print "'\''" $0 "'\'', "}
NR==14 {print "'\''" $0 "'\'', "}
NR==15 {print "'\''" $0 "'\'', '\'\'', '\'\'', '\'\'', "}
NR==31 {print "'\''" $0 "'\'', "}
NR==33 {print "'\''" $0 "'\'', "}
NR==37 {print "'\''" $0 "'\''"}
' > "${SQL_FILE}"


Print "[ OK ] SQL Statement in $SQL_FILE"

cat "$SQL_FILE"

mysql -u root -pcaracas ykm_data < "$SQL_FILE"

Print "[ OK ] Datos insertados"

#
##################################################




