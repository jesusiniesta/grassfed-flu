#!/usr/bin/python3.4

# before you go any further:
# 
# pip3 install beautifulsoup4
# 
import urllib.request
from bs4 import BeautifulSoup as Soup

rr = { 
	'AN'       : [],
	'AR'       : [],
	'AS'       : [],
	'IB'       : [],
	'CN'       : [],
	'CB'       : [],
	'CM'       : [],
	'CL'       : [],
	'CT'       : [],
	'VC'       : [],
	'EX'       : [],
	'GA'       : [],
	'MD'       : [],
	'MC'       : [],
	'NC'       : [],
	'PV'       : [],
	'RI'       : [],
	'CE'       : [],
	'ML'       : [],
	'Nac.' : []
}

# region codes according to ISO-3166-2 (http://www.geonames.org/ES/administrative-division-spain.html)
ISO = {'Andalucia': 'AN' ,
 'Aragón': 'AR' ,
 'Asturias': 'AS' ,
 'Baleares': 'IB' ,
 'Canarias': 'CN' ,
 'Cantabria': 'CB' ,
 'Castilla-La Mancha': 'CM' ,
 'Castilla y León': 'CL' ,
 'Cataluña': 'CT' ,
 'C. Valenciana': 'VC' ,
 'Extremadura': 'EX' ,
 'Lab. Vigo-Ourense': 'GA' ,
 'Madrid': 'MD' ,
 'Lab. Murcia': 'MC' ,
 'Navarra': 'NC' ,
 'País Vasco': 'PV' ,
 'La Rioja': 'RI' ,
 'Ceuta': 'CE' ,
 'Melilla': 'ML' ,
 'Nacional': 'Nac.'}

# and in reverse
ISOr = {
 'AN'  : 'Andalucia'         ,
 'AR'  : 'Aragón'            ,
 'AS'  : 'Asturias'          ,
 'IB'  : 'Baleares'          ,
 'CN'  : 'Canarias'          ,
 'CB'  : 'Cantabria'         ,
 'CM'  : 'Castilla-La Mancha',
 'CL'  : 'Castilla y León'   ,
 'CT'  : 'Cataluña'          ,
 'VC'  : 'C. Valenciana'     ,
 'EX'  : 'Extremadura'       ,
 'GA'  : 'Lab. Vigo-Ourense' ,
 'MD'  : 'Madrid'            ,
 'MC'  : 'Lab. Murcia'       ,
 'NC'  : 'Navarra'           ,
 'PV'  : 'País Vasco'        ,
 'RI'  : 'La Rioja'          ,
 'CE'  : 'Ceuta'             ,
 'ML'  : 'Melilla'           ,
 'Nac.': 'Nacional'          }

def DownloadSeason (start, length):

	for week in range(1,length+1):

		boletin = start + week - 1
		url = 'http://vgripe.isciii.es/gripe/PresentarHomeBoletin.do?boletin=1&bol='+str(boletin)
		soup = Soup( urllib.request.urlopen(url).read().decode('iso-8859-1','ignore') )

		# i want a table such that table>tbody>tr:nth-child(3)>td:first-child>font .getText() == Andalucíaç
		# it'll prolly be the last one too
		last_table = soup.find_all('table')[-1]

		regions = list(map( lambda x: x.text.replace('\n\xa0',''), 
		                    last_table.find_all(id="r1c1") ))

		ratios = list(map( lambda x: x.text.replace('\n','')
		                                    .replace('\r','')
		                                    .replace('\t','')
		                                    .replace('( gráficos )','')
		                                    .replace('( grficos )','')
		                                    .replace(' ','')
		                                    .replace(',','.') # decimal mark
		                                    .replace('Desc.', '-1'), # canarias
		                    last_table.find_all(id="r1c7") ))

		for i in range(0,len(ratios)):
			if (regions[i] in ISO):
				rr[ ISO[regions[i]] ].append( float(ratios[i]) )

	result = ''

	for r in sorted(list(rr.keys())):
		if r == 'Nac.': continue
		result += ISOr[r] + ' (' + r + ')\t' + '\t'.join(str(x) for x in rr[r])+'\n'

	return result

seasons = [('2014_2015', 473, 24),
           ('2013_2014', 428, 32),
           ('2012_2013', 381, 32),
           ('2011_2012', 338, 32)]         

for tseason in seasons:
	f = open('season_' + tseason[0] + '.tsv', "w")
	f.write(DownloadSeason(tseason[1], tseason[2]))
	f.close()


'''
NOTES:

http://vgripe.isciii.es/gripe/PresentarHomeBoletin.do?boletin=1&bol=486

temporada 2014-2015
===================
bol 473-498 => 25 semanas
Semana 40 / 2014 (29 de septiembre al 5 de octubre de 2014)
'''
