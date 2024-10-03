#!/bin/bash

# Vraag gebruiker om informatie voor het certificaatverzoek
read -p "Voer de gemeenschappelijke naam (CN) in: " common_name
read -p "Voer de organisatie (O) in: " organization
read -p "Voer de afdeling (OU) in: " organizational_unit
read -p "Voer de locatie (L) in: " locality
read -p "Voer de staat (ST) in: " state

# Zorg ervoor dat de landcode precies 2 tekens lang is
while true; do
    read -p "Voer het land (C) in (2-letter code): " country
    if [[ ${#country} -eq 2 ]]; then
        break
    else
        echo "De landcode moet precies 2 tekens lang zijn. Probeer het opnieuw."
    fi
done

# Vraag gebruiker om alternatieve domeinnamen (DNS alternative names)
read -p "Voer alternatieve domeinnamen gescheiden door komma's in (bijv. example.com,www.example.com): " alt_names

# Vraag gebruiker om bestandsnaam voor het certificaatverzoek
read -p "Voer de gewenste bestandsnaam voor het certificaatverzoek in (bijv. my_certificate_request): " csr_filename

# Gebruik dezelfde bestandsnaam voor de private key en voeg extensies toe
private_key_filename="${csr_filename}.key"
csr_filename="${csr_filename}.csr"

# Genereer het configuratiebestand voor OpenSSL
cat > openssl.cnf <<EOL
[req]
default_bits = 4096
prompt = no
default_md = sha256
req_extensions = req_ext
distinguished_name = dn

[dn]
CN = $common_name
O = $organization
OU = $organizational_unit
L = $locality
ST = $state
C = $country

[req_ext]
subjectAltName = @alt_names

[alt_names]
EOL

# Als alternatieve namen leeg zijn, voeg alleen de common name toe als SAN
if [ -z "$alt_names" ]; then
  echo "DNS.1 = $common_name" >> openssl.cnf
else
  IFS=',' read -ra ALT_NAMES <<< "$alt_names"
  for i in "${!ALT_NAMES[@]}"; do
    echo "DNS.$((i+1)) = ${ALT_NAMES[$i]}" >> openssl.cnf
  done
fi

# Genereer het certificaatverzoek en private key zonder wachtwoord met 4096 bits encryptie
openssl req -new -newkey rsa:4096 -keyout "$private_key_filename" -out "$csr_filename" -config openssl.cnf -nodes

# Toon bericht dat het certificaatverzoek is gegenereerd
echo "Het certificaatverzoek is gegenereerd: $csr_filename"
echo "De private key is opgeslagen in: $private_key_filename"
