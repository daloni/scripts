#!/bin/bash
#########################################################
#	Variables					#
#########################################################
DPKG=$(which dpkg)
APT_GET=$(which apt-get)
DHCP=$(echo isc-dhcp-server)
DIALOG=$(echo dialog)
INTERFACES=$(echo "/etc/network/interfaces")
#/etc/network/interfaces
TEMPFILE=$(echo /tmp/file.script)
DHCPD=$(echo "/etc/dhcp/dhcpd.conf")
#/etc/dhcp/dhcpd.conf
FADATP=$(echo "/etc/default/isc-dhcp-server")
#/etc/default/isc-dhcp-server
#########################################################
#	Tienes permisos?				#
#########################################################
if [ "$SHELL" = "$BASH" ]; then {
if [ -n "$(id | grep root)" ]; then {
#########################################################
#	Paquetes					#
#########################################################
SORTIDA=""
SORTIDA=$($DPKG --get-selections $DHCP)
if [ "$SORTIDA" = "" ]; then
	$APT_GET install -y $DHCP
else
	echo "El paquete '$DHCP' ya està instalado"
fi
SORTIDA=""
SORTIDA=$($DPKG --get-selections $DIALOG)
if [ "$SORTIDA" = "" ]; then
	$APT_GET install -y $DIALOG
else
	echo "El paquete '$DIALOG' ya està instalado"
fi
#########################################################
#	Elecion del adaptador				#
#########################################################
ADAPTADOR=""
while [ "$ADAPTADOR" = "" ]; do
ADAPTADOR=$(dialog --stdout --title "Tipo de adaptador:" \
	--menu "Elige el adaptador de tu red" 11 50 5 \
	"eth0" "Adaptador de cable" \
	"eth1" "Adaptador de cable 2" \
	"wlan0" "Adaptador de wifi" \
	"Otro"	"Elegir otro adaptador" )
		case $ADAPTADOR in
		Otro)	
			ADAPTADOR=$(dialog --stdout --title "Tipo de adaptador:" \
			--inputbox "Que adaptador quieres?" 8 40 );;
		esac
	clear
	echo "Has elegido '$ADAPTADOR'"
done
#########################################################
#	Revision del adaptador				#
#########################################################
if [ "$(grep $ADAPTADOR $INTERFACES | grep static)" ]; then
	echo Este adaptador ya tiene un ip fija
	dialog --title "IP fija" \
	--yesno "Quieres cambiar tu IP fija?" 5 33
else
	echo El adaptador tiene que tener una IP fija
	SINO="0"
fi
#########################################################
#	Edicion del fichero "interfaces"		#
#########################################################
SINO=$?
clear
case $SINO in
	0)	
#########################################################
#	Selecion de IP					#
#########################################################
NETWORK=""
while [ "$NETWORK" = "" ]; do
	NETWORK=$(dialog --stdout --title "Que red quieres usar?" \
	--menu "Classe C por defecto" 11 50 5 \
	"192.168.10.0" "Clase C" \
	"172.16.0.0" "Clase B" \
	"10.0.0.0" "Clase A" \
	"Otra"	"Elegir otra dirección IP" )
		case $NETWORK in
		Otra)	
			NETWORK=$(dialog --stdout --title "Elige tu IP:" \
			--backtitle "(Acaba en 0)" \
			--inputbox "Pon una IP fija a tu servidor:" 8 40 );;
		esac
	clear
done
#########################################################
#	Cambio de IP					#
#########################################################
		IP=$(echo $NETWORK | sed 's/.$/1/')
		MASK=$(echo $NETWORK | sed 's/\./\n/' | head -n 1)
		if [ $MASK -lt 128 ]; then NUMMASK="3"
		elif [ $MASK -gt 191 ]; then
			if [ $MASK -gt 254 ]; then echo "La IP no es válida"; exit 0
			else
			NUMMASK="1"
			fi
		else NUMMASK="2"
		fi
		if [ "$(grep $ADAPTADOR $INTERFACES)" ]; then
			echo "" >> $INTERFACES
			echo "auto" >> $INTERFACES
			L1=$(cat -n $INTERFACES | grep "auto $ADAPTADOR" | cut -f1)
			L2=$(cat -n $INTERFACES | grep auto | cut -f1 | grep -A 1 -w $L1 | tail -n 1)
			L2=$(expr $L2 - 1)
			sed -i "$L1","$L2"d $INTERFACES
			sed -i '$d' $INTERFACES
			sed -i '$d' $INTERFACES
		fi
		echo "" >> $INTERFACES
		echo "auto $ADAPTADOR" >> $INTERFACES
		echo "iface $ADAPTADOR inet static"  >> $INTERFACES
		KSAM=$(expr 4 - $NUMMASK) 
		echo 1.2.3.4 > $TEMPFILE
		sed -i 's/\./\n/g' $TEMPFILE
		for i in $(seq $KSAM); do sed -i s/^"$i"$/255/g $TEMPFILE ; done
		for i in $(seq $NUMMASK); do sed -i '$d' $TEMPFILE ; done
		for i in $(seq $NUMMASK); do echo 0 >> $TEMPFILE ; done
		MASK=$(cat $TEMPFILE | fmt | sed 's/\ /./g')
		echo "address $IP" >> $INTERFACES
		echo "netmask $MASK" >> $INTERFACES
		echo "Ya hemos elegido IP"
		echo "Reniciando el servicio..."
		/etc/init.d/networking restart
		;;
	1)
		NETWORK=$(grep -A3 $ADAPTADOR $INTERFACES | grep -A3 static | grep address | sed s/address// | sed s/\ // | sed s/\..$/\.0/)
		IP=$(grep -A3 $ADAPTADOR $INTERFACES | grep -A3 static | grep address | sed s/address// | sed s/\ //)
		MASK=$(grep -A3 $ADAPTADOR $INTERFACES | grep -A3 static | grep netmask | sed s/netmask// | sed s/\ //)
		echo "La IP no se ha modificado"
		;;
	255) 
		echo "No se ha podido cambiar la IP"
		exit 1
		;;
esac
#########################################################
#	DHCP						#
#########################################################
if [ "$(grep '^subnet' $DHCPD)" ]; then
	while [ "$(grep '^subnet' $DHCPD)" != "" ]; do
		let i=1
		L1=$(cat $DHCPD | grep -nw '^subnet' | cut -d ':' -f1)
		while [ "$(cat $DHCPD | grep -A $i -nw '^subnet' | grep '}')" = "" ]; do
			let i=$i+1
		done
		L2=$(cat $DHCPD | grep -A $i -nw '^subnet' | grep '}' | cut -d '-' -f1)
		WC=$(echo $L1 | tr ' ' '\n' | wc -l)
		for e in $(seq $WC); do
			L3=$(echo $L1 | cut -d ' ' -f$e)
			L4=$(echo $L2 | cut -d ' ' -f$e)
			sed -i "$L3","$L4"d $DHCPD 2>/dev/null
		done
	done
fi
	let MIN=$(dialog --stdout --rangebox "Rango de IP que darà el servidor DCHP. Mín:" 2 50 2 250 10)
	RMIN=$(echo $NETWORK | sed s/.$/"$MIN"/g)
	MIN=$(expr $MIN + 1)
	let MAX=$(dialog --stdout --rangebox "Rango de IP que darà el servidor DCHP. Max:" 2 50 $MIN 251 250)
	RMAX=$(echo $NETWORK | sed s/.$/"$MAX"/g)
	BROADCAST=$(echo $NETWORK | sed s/.$/255/g)
	echo "subnet $NETWORK netmask $MASK {" >> $DHCPD
	echo -e "\trange $RMIN $RMAX;" >> $DHCPD
	echo -e "\toption domain-name-servers $IP, 8.8.8.8;" >> $DHCPD
	echo -e "\toption routers $IP;" >> $DHCPD
	echo -e "\toption broadcast-address $BROADCAST;" >> $DHCPD
	echo "}" >> $DHCPD
if [ "$(grep 'INTERFACES=' $FADATP)" ]; then
	ADAPT=$(cat -n $FADATP | grep INTERFACES | cut -f1)
	ADAPT=$(expr $ADAPT)
	sed -i "$ADAPT"d $FADATP
fi
echo "INTERFACES=\"$ADAPTADOR\"" >> $FADATP
#########################################################
#	Final						#
#########################################################
/etc/init.d/isc-dhcp-server restart
	echo "El web servidor está funcionando"
#########################################################
# Error de permisos					#
#########################################################
}
else
	echo "No tengo permisos de escritura en scripts"
fi
}
else
	echo "La shell no es adecuada, ejecuta:"
	echo " sudo bash $0"
fi
