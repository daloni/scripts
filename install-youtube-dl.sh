while [ "which zenity" = "" ]; do
	sudo `which apt-get` install zenity
done
while [ "which youtube-dl" = "" ]; do
	sudo `which apt-get` install youtube-dl
done
DESKTOP_DIR=$(grep "DESKTOP" ~/.config/user-dirs.dirs | cut -d '"' -f 2 | cut -d '/' -f2)
DIR=$(zenity --file-selection --directory / --title="Donde se guardara la música descargada?")
cd && mkdir .scripts/ 2>/dev/null
cd .scripts/
echo "cd $DIR" > youtube.sh
echo 'URL=$(zenity --entry --title="URL" --text="Pon la URL para descargar al audio en mp3")' >> youtube.sh
echo 'youtube-dl -x --audio-format="mp3" -o "./%(title)s.%(ext)s" $URL | zenity --progress --percentage=0 --auto-close' >> youtube.sh
chmod +x youtube.sh
wget "http://www.youtube.com/yt/brand/media/image/YouTube-logo-full_color.png" -O "youtube.png" 2>/dev/null
cd  && cd $DESKTOP_DIR
echo "[Desktop Entry]" > youtube.desktop
echo "Type=Application" >> youtube.desktop
echo "Icon=$HOME/.scripts/youtube.png" >> youtube.desktop
echo "Name=Youtube-mp3" >> youtube.desktop
echo "Exec=$HOME/.scripts/youtube.sh" >> youtube.desktop
chmod +x youtube.desktop
echo "ACABADO!!"
