
## examples of use
# C:\Users\ikun\Desktop\project
# λ gawk -f grassfed-flu\select.geonames.awk data\geonames\ES.txt > data/geonames/ES.P.dat
# 
# C:\Users\ikun\Desktop\project
# λ gawk -f grassfed-flu\select.geonames.awk data\geonames\ES.txt > data/geonames/ES.dat


# http://download.geonames.org/export/dump/

BEGIN {
	FS="\t";
	OFS="|";

	geonameid        = 1;
	name             = 2;
	asciiname        = 3;
	alternatenames   = 4;
	latitude         = 5;
	longitude        = 6;
	featureclass     = 7;
	featurecode      = 8;
	countrycode      = 9;
	cc2              = 10;
	admin1code       = 11;
	admin2code       = 12;
	provincia        = 12;
	admin3code       = 13;
	admin4code       = 14;
	population       = 15;
	elevation        = 16;
	dem              = 17;
	timezone         = 18;
	modificationdate = 19;

 	print     "geonameid","provincia","asciiname","latitude","longitude","featureclass","featurecode","population";

}

{
	if ($featureclass == "P") {
		print $geonameid, $provincia, $asciiname, $latitude, $longitude, $featureclass, $featurecode, $population;
	}
}

## feature classes (http://www.geonames.org/export/codes.html)
# A : country, state, region,..."
# H : stream, lake, ..."
# L : parks,area, ..."
# P : city, village,..."
# R : road, railroad "
# S : spot, building, farm"
# T : mountain,hill,rock,... "
# U : undersea"
# V : forest,heath,..."

## Columns
# * A/1: geonameid         : integer id of record in geonames database
#   B/2: name              : name of geographical point (utf8) varchar(200)
# * C/3: asciiname         : name of geographical point in plain ascii characters, varchar(200)
#   d/4: alternatenames    : alternatenames, comma separated, ascii names automatically transliterated, convenience attribute from alternatename table, varchar(10000)
# * e/5: latitude          : latitude in decimal degrees (wgs84)
# * f/6: longitude         : longitude in decimal degrees (wgs84)
# * g/7: feature class     : see http://www.geonames.org/export/codes.html, char(1)
#   h/8: feature code      : see http://www.geonames.org/export/codes.html, varchar(10)
#   i/9: country code      : ISO-3166 2-letter country code, 2 characters
#   j/10: cc2               : alternate country codes, comma separated, ISO-3166 2-letter country code, 60 characters
#   k/11: admin1 code       : fipscode (subject to change to iso code), see exceptions below, see file admin1Codes.txt for display names of this code; varchar(20)
# * l/12: admin2 code       : code for the second administrative division, a county in the US, see file admin2Codes.txt; varchar(80)
#   m/13: admin3 code       : code for third level administrative division, varchar(20)
#   n/14: admin4 code       : code for fourth level administrative division, varchar(20)
# * o/15: population        : bigint (8 byte int)
#   p/16: elevation         : in meters, integer
#   q/17: dem               : digital elevation model, srtm3 or gtopo30, average elevation of 3''x3'' (ca 90mx90m) or 30''x30'' (ca 900mx900m) area in meters, integer. srtm processed by cgiar/ciat.
#   r/18: timezone          : the timezone id (see file timeZone.txt) varchar(40)
#   s/19: modification date : date of last modification in yyyy-MM-dd format

## provinces according to http://download.geonames.org/export/dump/admin2Codes.txt
# V  : València
# TO : Toledo
# SE : Sevilla
# TF : Santa Cruz de Tenerife
# MA : Málaga
# GC : Las Palmas
# J  : Jaén
# H  : Huelva
# GR : Granada
# CU : Cuenca
# CO : Córdoba
# CR : Ciudad Real
# CA : Cádiz
# CC : Cáceres
# BA : Badajoz
# AL : Almería
# A  : Alicante
# AB : Albacete
# Z  : Zaragoza
# ZA : Zamora
# BI : Bizkaia
# VA : Valladolid
# TE : Teruel
# T  : Tarragona
# SO : Soria
# SG : Segovia
# S  : Cantabria
# SA : Salamanca
# PO : Pontevedra
# P  : Palencia
# OR : Ourense
# LU : Lugo
# LE : León
# C  : Coruña
# HU : Huesca
# SS : Gipuzkoa
# GU : Guadalajara
# CS : Castelló
# BU : Burgos
# B  : Barcelona
# AV : Ávila
# VI : Araba / Álava
# GI : Girona
# L  : Lleida
# LO : La Rioja
# M  : Madrid
# MU : Murcia
# NA : Navarra
# O  : Asturias
# PM : Illes Balears
# CE : Ceuta
# ME : Melilla

## feature codes for class P (see http://www.geonames.org/export/codes.html)
#PPL	populated place	a city, town, village, or other agglomeration of buildings where people live and work
#PPLA	seat of a first-order administrative division	seat of a first-order administrative division (PPLC takes precedence over PPLA)
#PPLA2	seat of a second-order administrative division	
#PPLA3	seat of a third-order administrative division	
#PPLA4	seat of a fourth-order administrative division	
#PPLC	capital of a political entity	
#PPLCH	historical capital of a political entity	a former capital of a political entity
#PPLF	farm village	a populated place where the population is largely engaged in agricultural activities
#PPLG	seat of government of a political entity	
#PPLH	historical populated place	a populated place that no longer exists
#PPLL	populated locality	an area similar to a locality but with a small group of dwellings or other buildings
#PPLQ	abandoned populated place	
#PPLR	religious populated place	a populated place whose population is largely engaged in religious occupations
#PPLS	populated places	cities, towns, villages, or other agglomerations of buildings where people live and work
#PPLW	destroyed populated place	a village, town or city destroyed by a natural disaster, or by war
#PPLX	section of populated place	
#STLMT	israeli settlement
