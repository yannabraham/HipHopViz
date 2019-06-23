'''
Created on 07.03.2013

@author: ABRAHYA1
'''

from sqlalchemy import *
from sqlalchemy.orm import *

## prepare DB
engine = create_engine('sqlite:///site/data/HipHopFull.db')

if __name__=='__main__':
    meta = MetaData(engine)
    meta.reflect(views=True)
    print meta.tables.keys()
    hiphop = meta.tables['hiphop_v']
    genes = meta.tables['genes']
    experiments = meta.tables['experiments']
    
    inspect = inspect(engine)
    
    for item in inspect.get_foreign_keys('hiphop'):
        print item['referred_table']+':'
        for col in item['referred_columns']:
            print '\t'+col
    
    Session = sessionmaker(engine)
    session = Session()
    
    res = session.query(genes).filter(genes.columns.Systematic_name=='YAL011W')
    for row in res:
        print row
    
#    res = session.query(hiphop,genes,experiments).\
#        join(genes).\
#        join(experiments).\
#        filter(hiphop.columns.gene_id=='YAL011W')
    res = session.query(hiphop).filter(hiphop.columns.gene_id=='YAL011W')
    
    for row in res:
        print row