## base imports
import os, os.path

## web imports
import cherrypy
from cherrypy.process import wspbus, plugins
import json

from mako.template import Template
from mako.lookup import TemplateLookup

## DB imports
from sqlalchemy import *
from sqlalchemy.orm import *

## prepare DB
engine = create_engine('sqlite:///site/data/HipHopFull.db')

class SAEnginePlugin(plugins.SimplePlugin):
    def __init__(self, bus):
        """
        The plugin is registered to the CherryPy engine and therefore
        is part of the bus (the engine *is* a bus) registery.
 
        We use this plugin to create the SA engine. At the same time,
        when the plugin starts we create the tables into the database
        using the mapped class of the global metadata.
 
        Finally we create a new 'bind' channel that the SA tool
        will use to map a session to the SA engine at request time.
        """
        plugins.SimplePlugin.__init__(self, bus)
        self.sa_engine = None
        self.bus.subscribe("bind", self.bind)
 
    def start(self):
        self.sa_engine = engine
 
    def stop(self):
        if self.sa_engine:
            self.sa_engine.dispose()
            self.sa_engine = None
 
    def bind(self, session):
        session.configure(bind=self.sa_engine)
 
class SATool(cherrypy.Tool):
    def __init__(self):
        """
        The SA tool is responsible for associating a SA session
        to the SA engine and attaching it to the current request.
        Since we are running in a multithreaded application,
        we use the scoped_session that will create a session
        on a per thread basis so that you don't worry about
        concurrency on the session object itself.
 
        This tools binds a session to the engine each time
        a requests starts and commits/rollbacks whenever
        the request terminates.
        """
        cherrypy.Tool.__init__(self, 'on_start_resource',
                               self.bind_session,
                               priority=20)
 
        self.session = scoped_session(sessionmaker(autoflush=True,
                                                  autocommit=False))
 
    def _setup(self):
        cherrypy.Tool._setup(self)
        cherrypy.request.hooks.attach('on_end_resource',
                                      self.commit_transaction,
                                      priority=80)
 
    def bind_session(self):
        cherrypy.engine.publish('bind', self.session)
        cherrypy.request.db = self.session
 
    def commit_transaction(self):
        cherrypy.request.db = None
        try:
            self.session.commit()
        except:
            self.session.rollback()  
            raise
        finally:
            self.session.remove()

## prepare server
current_dir = os.path.dirname(os.path.abspath(__file__))
lookup = TemplateLookup(directories=['site/html'],module_directory='site/tmp/mako_modules')

conf = {
        'global' : {
                    'server.socket_host' : '0.0.0.0',
                    'server.socket_port' : 8080
                    },
        '/' : {
               'tools.db.on': True,
               'tools.staticdir.root': os.path.abspath("site/")
               },
        '/site' : {
                   'tools.etags.on': True,
                   'tools.staticdir.on': True,
                   'tools.staticdir.dir': '.'
                   },
        '/js' : {
                    'tools.staticdir.on': True,
                    'tools.staticdir.dir': 'js'
                },
        '/style' : {
                    'tools.staticdir.on': True,
                    'tools.staticdir.dir': 'style'
                    }
        }

class Root(object):
    def __init__(self):
        self.meta = MetaData(engine)
        self.meta.reflect(views=True)
        self.hiphop = self.meta.tables['hiphop_v']
        self.gene_correlation = self.meta.tables['gene_correlation_v']
        self.compound_correlation = self.meta.tables['compound_correlation_v']
        self.genes = self.meta.tables['genes']
        self.compounds = self.meta.tables['compounds']
        self.experiments = self.meta.tables['experiments_v']
    
    @cherrypy.expose
    def conf(self):
        # set headers
        cherrypy.response.headers['content-type'] = 'text/plain'
        print cherrypy.config.keys()
        return 
    
    @cherrypy.expose
    def index(self):
        tmpl = lookup.get_template("index.html")
        return tmpl.render()
    
    @cherrypy.expose
    def compoundQueryJson(self,term=None,lim=10):
        # set query
        query = cherrypy.request.db.query(self.compounds)
        # get results
        if(term is None):
            res = query.limit(lim).with_entities(self.compounds.columns.compound_id,self.compounds.columns.compound_name).all()
        else:
            res = query.\
                        filter(or_(self.compounds.columns.compound_id.like('%'+term+'%'),
                                   self.compounds.columns.compound_name.like('%'+term+'%'))).\
                        limit(lim).\
                        with_entities(self.compounds.columns.compound_id,self.compounds.columns.compound_name).\
                        all()
        if len(res)>0:
            src = []
            for row in res:
                if row[1]=='':
                    src.append({'label':str(row[0]),'value':row[0]})
                else:
                    src.append({'label':row[1],'value':row[0]})
        else:
            src = None
        return json.dumps(src)
    
    @cherrypy.expose
    def geneQueryJson(self,term=None,lim=10):
        # set query
        query = cherrypy.request.db.query(self.genes)
        # get results
        if(term is None):
            res = query.limit(lim).with_entities(self.genes.columns.Systematic_name,self.genes.columns.Common_name).all()
        else:
            res = query.\
                        filter(or_(self.genes.columns.Systematic_name.like('%'+term+'%'),
                                   self.genes.columns.Common_name.like('%'+term+'%'))).\
                        limit(lim).\
                        with_entities(self.genes.columns.Systematic_name,self.genes.columns.Common_name).\
                        all()
        if len(res)>0:
            src = []
            for row in res:
                if row[1]=='':
                    src.append({'label':str(row[0]),'value':row[0]})
                else:
                    src.append({'label':row[1],'value':row[0]})
        else:
            src = None
        return json.dumps(src)
    
    @cherrypy.expose
    def compound2experimentJson(self,queryID=991,lim=None):
        if type(queryID)==type(''):
            if queryID.find(',')>0:
                queryID = queryID.split(',')
            else:
                queryID = [queryID]
        # set query
        query = cherrypy.request.db.query(self.experiments)
        # get results
        res = query.filter(self.experiments.columns.compound_id.in_(queryID)).limit(lim).all()
        if len(res)>0:
            if res[0].id==None:
                res.pop(0)
            res = [row._asdict() for row in res]
        else:
            res = None
        return json.dumps(res)
    
    @cherrypy.expose
    def resultsJson(self,base='gene',queryID='YAL011W',lim=None):
        if type(queryID)==type(''):
            if queryID.find(',')>0:
                queryID = queryID.split(',')
            else:
                queryID = [queryID]
        if base=='gene':
            base = 'Systematic_name'
        elif base=='compound':
            base = 'compound_id'
        else:
            return None
        # set headers
        cherrypy.response.headers['content-type'] = 'text/plain'
        # set query
        query = cherrypy.request.db.query(self.hiphop)
        # get results
        res = query.filter(self.hiphop.columns[base].in_(queryID)).limit(lim).all()
        if len(res)>0:
            if res[0].id==None:
                res.pop(0)
            res = [row._asdict() for row in res]
        else:
            res = None
        return json.dumps(res)
    
    @cherrypy.expose
    def results(self,base='gene',ID='YAL011W',lim=None):
        tmpl = lookup.get_template("results.html")
        if lim is None:
            lim = ''
        if base=='gene':
            baseCol = 'gene_id'
            dest = 'compound'
            destCol = 'compound_id'
            prettyName = 'compound_name'
            score = 'z-score'
            scoreCol = 'z_score'
            fullName=ID
            fullBase='strain with deletion in'
            fullDest = 'the corresponding compounds accross all strains'
        else:
            baseCol = 'compound_id'
            dest = 'gene'
            destCol = 'gene_id'
            prettyName = 'Common_name'
            score = 'sensitivity score'
            scoreCol = 'madl_score'
            fullName = 'CMB'+ID
            fullBase = base
            fullDest = 'the strain with a deletion in the corresponding gene across all tested compounds'
        return tmpl.render(base=base,ID=ID,lim=lim,baseCol=baseCol,dest=dest,destCol=destCol,prettyName=prettyName,
                           score=score,scoreCol=scoreCol,fullName=fullName,fullBase=fullBase,fullDest=fullDest)
    
    @cherrypy.expose
    def profile(self,base='gene',ID='YAL011W',lim=None):
        tmpl = lookup.get_template("profile.html")
        if lim is None:
            lim = ''
        if base=='gene':
            baseCol = 'gene_id'
            dest = 'compound'
            destCol = 'compound_id'
            prettyName = 'compound_name'
            score = 'z-score'
            scoreCol = 'z_score'
            fullName = ID
            fullBase = 'strain with deletion in'
            xAxisLabel = dest
            target = 'results'
        else:
            baseCol = 'compound_id'
            dest = 'gene'
            destCol = 'gene_id'
            prettyName = 'Common_name'
            score = 'sensitivity score'
            scoreCol = 'madl_score'
            fullName = 'CMB'+ID
            fullBase = base
            xAxisLabel='chromosome location'
            target = 'profile'
        return tmpl.render(base=base,ID=ID,lim=lim,baseCol=baseCol,dest=dest,destCol=destCol,prettyName=prettyName,
                           score=score,scoreCol=scoreCol,fullName=fullName,fullBase=fullBase,xAxisLabel=xAxisLabel,
                           target=target
               )
    
    @cherrypy.expose
    def geneCorrelationJson(self,correlationType='HIP',queryID='YAL011W',lim=None):
        if type(queryID)==type(''):
            if queryID.find(',')>0:
                queryID = queryID.split(',')
            else:
                queryID = [queryID]
        if correlationType=='HIP':
            correlationType = 'HIP-HIP correlation'
        else:
            correlationType = 'HOP-HOP correlation'
        # set headers
        cherrypy.response.headers['content-type'] = 'text/plain'
        # set query
        query = cherrypy.request.db.query(self.gene_correlation)
        # get the data
        res = query.filter(self.gene_correlation.columns.Type==correlationType,
                           self.gene_correlation.columns.Systematic_name1.in_(queryID)).limit(lim).all()
        if len(res)>0:
            if res[0].id==None:
                res.pop(0)
            res = [row._asdict() for row in res]
        else:
            res = None
        return json.dumps(res)
    
    @cherrypy.expose
    def geneCorrelation(self,correlationType='HIP',geneID='YAL011W',lim=None):
        tmpl = lookup.get_template('GeneCorrelation.html')
        if lim is None:
            lim=''
        corType = 'heterozygous'
        if correlationType=='HOP':
            corType = 'homozygous' 
        return tmpl.render(geneID=geneID,lim=lim,correlationType=correlationType,corType=corType)
    
    @cherrypy.expose
    def compoundCorrelationJson(self,correlationType='HIP',queryID=None,lim=None):
        if type(queryID)==type(''):
            if queryID.find(',')>0:
                queryID = queryID.split(',')
            else:
                queryID = [queryID]
        if correlationType=='HIP':
            correlationType = 'HIP-correlation'
        else:
            correlationType = 'HOP-correlation'
        # set headers
        cherrypy.response.headers['content-type'] = 'text/plain'
        # set query
        query = cherrypy.request.db.query(self.compound_correlation)
        # get the data
        res = query.filter(self.compound_correlation.columns.Type==correlationType,
                           self.compound_correlation.columns.compound_id1.in_(queryID)).limit(lim).all()
        if res[0].id==None:
            res.pop(0)
        res = [row._asdict() for row in res]
        return json.dumps(res)
    
    @cherrypy.expose
    def compoundCorrelation(self,correlationType='HIP',compoundID=None,lim=None):
        tmpl = lookup.get_template('CompoundCorrelation.html')
        if lim is None:
            lim=''
        return tmpl.render(compoundID=compoundID,lim=lim,correlationType=correlationType)

if __name__ == '__main__':
    SAEnginePlugin(cherrypy.engine).subscribe()
    cherrypy.tools.db = SATool()
    cherrypy.config.update(conf['global'])
    cherrypy.tree.mount(Root(), config=conf , script_name = '/hiphop' )
    cherrypy.engine.start()
    cherrypy.engine.block()
