#!/bin/bash
#########################################################
#	Variables					#
#########################################################
DPKG=$(which dpkg)
APT_GET=$(which apt-get)
DHCP=$(echo isc-dhcp-server)
DIALOG=$(echo dialog)
INTERFACES=$(echo ./interfaces)
#/etc/network/interfaces
TEMPFILE=$(echo /tmp/file.script)
#########################################################
#	Tienes permisos?				#
#########################################################
if [ -n "$(id | grep root)" ]; then {
#########################################################
#	Paquetes					#
#########################################################
SORTIDA=""
SORTIDA=$($DPKG -l $DIALOG)
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
	ipstat=$(echo Este adaptador tiene una IP fija)
else
	ipstat=$(echo El adaptador está configurado por DHCP)
fi

#########################################################
#	Edicion del fichero "interfaces"		#
#########################################################
SINO=$(dialog --stdout --title "Configura tu adaptador:" \
	--menu "$ipstat" 11 35 5 \
	"0" "Estática" \
	"1" "DCHP" \
	"2" "Cancelar")
clear
#########################################################
#	Borrado de la configuracion anterior		#
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
		echo "" >> $INTERFACES
		echo "auto $ADAPTADOR" >> $INTERFACES
		echo "iface $ADAPTADOR inet static"  >> $INTERFACES
		IP=$(echo $NETWORK | sed 's/.$/1/')
		MASK=$(echo $NETWORK | sed 's/\./\n/' | head -n 1)
		if [ $MASK -lt 128 ]; then NUMMASK="3"
		elif [ $MASK -gt 191 ]; then NUMMASK="1"
		else NUMMASK="2"
		fi
		KSAM=$(expr 4 - $NUMMASK) 
		echo 1.2.3.4 > $TEMPFILE
		sed -i 's/\./\n/g' $TEMPFILE
		for i in $(seq $KSAM); do sed -i s/^"$i"$/255/g $TEMPFILE ; done
		for i in $(seq $NUMMASK); do sed -i '$d' $TEMPFILE ; done
		for i in $(seq $NUMMASK); do echo 0 >> $TEMPFILE ; done
		MASK=$(cat $TEMPFILE | fmt | sed 's/\ /./g')
		echo $MASK > $TEMPFILE
		echo "address $IP" >> $INTERFACES
		echo "netmask $MASK" >> $INTERFACES
		echo "Ya hemos elegido IP"
		/etc/init.d/networking restart
		;;
	1) 
		echo "" >> $INTERFACES
		echo "auto $ADAPTADOR" >> $INTERFACES
		echo "iface $ADAPTADOR inet static"  >> $INTERFACES
		;;
	2)
		echo "La IP no se ha modificado";;
	255)
		exit 0;;
esac
#########################################################
#	Final						#
#########################################################
	echo "El web servidor está funcionando"
}
#########################################################
# Error de permisos					#
#########################################################
else
	echo "No tengo permisos de escritura en scripts"
fi
