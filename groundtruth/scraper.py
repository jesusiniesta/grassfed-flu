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

for week in range(1,12+1):

	boletin = 486+week-1
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
		rr[ ISO[regions[i]] ].append( float(ratios[i]) )

for r in sorted(list(rr.keys())):
	if r == 'Nac.': continue
	print(r+'\t'+'\t'.join(str(x) for x in rr[r]))
