.header OFF
.mode tabs
.bail ON

PRAGMA foreign_keys = ON;

drop index if exists compound_id_idx;
drop index if exists gene_id_idx;
drop index if exists compound_concentration_experiment_type_idx;
drop index if exists Systematic_name1_idx;
drop index if exists compound_concentration_experiment_type1_idx;
drop view if exists experiments_v;
drop view if exists hiphop_v;
drop view if exists gene_correlation_v;
drop view if exists compound_correlation_v;
drop table if exists hiphop;
drop table if exists gene_correlation;
drop table if exists compound_correlation;
drop table if exists compound2experiment;
drop table if exists gene2annotation;
drop table if exists genes;
drop table if exists compounds;
drop table if exists experiments;

CREATE TEMP TABLE compounds_temp (
     compound_id INTEGER,
     compound_name TEXT,
     IC30 REAL,
     wikipedia TEXT,
     pubmed TEXT,
     moa TEXT
);

CREATE TEMP TABLE genes_temp (
     Systematic_name TEXT,
     Common_name TEXT,
     Alias TEXT,
     Description TEXT,
     CMB_description TEXT,
     NN_Systematic_name TEXT,
     NN_Common_name TEXT,
     NN_cor TEXT,
     NN_Description TEXT,
     NN_Type TEXT,
     EC_number TEXT,
     GeneID INTEGER,
     RefSeqProteinID TEXT,
     UniProtID TEXT,
     GOSLIM_Cellular_Component TEXT,
     GoID_Cellular_component TEXT,
     GOSLIM_Molecular_Function TEXT,
     GoID_Molecular_Function TEXT,
     GOSLIM_Biological_Process TEXT,
     GoID_Biological_Process TEXT,
     Uniq_GOSlim_Cellular_Component TEXT,
     Uniq_GOSlim_Biological_Process TEXT,
     Uniq_GOSlim_Molecular_Function TEXT,
     Phenotype TEXT,
     Phenotype_Systematic_deletion TEXT,
     Haploinsuficiency TEXT,
     Viability TEXT,
     Oshea_abundance INTEGER,
     Oshea_localization TEXT,
     Ortho_MCL_family TEXT
);

CREATE TEMP TABLE gene2annotation_temp (
     ext_id TEXT,
     db_id TEXT,
     db_ref TEXT,
     Systematic_name TEXT,
     SGD_ID TEXT,
     Common_name TEXT 
);
     
CREATE TEMP TABLE hiphop_temp (
     compound_id INTEGER,
     concentration REAL,
     experiment TEXT,
     experiment_group TEXT,
     compound_concentration TEXT,
     compound_concentration_experiment TEXT,
     compound_concentration_experiment_group TEXT,
     experiment_type TEXT,
     gene_id TEXT,
     madl_score REAL, 
     z_score REAL,
     score_type TEXT
);

CREATE TEMP TABLE gene_correlation_temp (
     Cluster_ORF_1 TEXT,
     Type TEXT,
     Cluster_ORF_2 TEXT,
     Correlation REAL,
     Min_Z_Score_1_2 REAL,
     Min_NegLog_FDR_1_2 REAL,
     Z_Score_Gene1 REAL,
     Z_Score_Gene2 REAL,
     NegLog_Pval_Gene1 REAL,
     NegLog_FDR_Gene1 REAL,
     NegLog_Pval_Gene2 REAL,
     NegLog_FDR_Gene2 REAL,
     Self TEXT,
     Systematic_name_pair TEXT,
     Common_name_pair TEXT,
     Systematic_name1 TEXT,
     Common_name1 TEXT,
     Viability1 TEXT,
     Systematic_name2 TEXT,
     Common_name2 TEXT,
     Viability2 TEXT 
);

CREATE TEMP TABLE compound_correlation_temp (
     Cluster_Experiment1 TEXT,
     NVP1 TEXT,
     Type TEXT,
     Cluster_Experiment2 TEXT,
     NVP2 TEXT,
     Correlation REAL,
     Min_Correlation REAL,
     Z_Score_1_2_min REAL,
     NegLog_FDR_1_2_min REAL,
     Z_Score_Cpd1 REAL,
     Min_Z_Score_Cpd1 REAL,
     Z_Score_Cpd2 REAL,
     Min_Z_Score_Cpd2 REAL,
     NegLog_Pval_Cpd1 REAL,
     NegLog_FDR_Cpd1 REAL,
     NegLog_Pval_Cpd2 REAL,
     NegLog_FDR_Cpd2 REAL,
     Self INTEGER,
     Common_name_pair TEXT,
     CMB_Id_pair TEXT,
     CMB_Id_Cpd1 INTEGER,
     Common_name1 INTEGER,
     Origin1 TEXT,
     External_contact1 INTEGER,
     Indication1 INTEGER,
     Target1 INTEGER,
     Remarks1 INTEGER,
     Cpd_category1 TEXT,
     CMB_Id_Cpd2 INTEGER,
     Common_name2 TEXT,
     Origin2 TEXT,
     External_contact2 TEXT,
     Indication2 TEXT,
     Target2 TEXT,
     Remarks2 TEXT,
     Cpd_category2 TEXT 
);

CREATE TABLE genes (
     id INTEGER PRIMARY KEY AUTOINCREMENT,
     Systematic_name TEXT UNIQUE,
     Common_name TEXT,
     Alias TEXT,
     Description TEXT,
     CMB_description TEXT,
     NN_Systematic_name TEXT,
     NN_Common_name TEXT,
     NN_cor TEXT,
     NN_Description TEXT,
     NN_Type TEXT,
     EC_number TEXT,
     GeneID INTEGER,
     RefSeqProteinID TEXT,
     UniProtID TEXT,
     GOSLIM_Cellular_Component TEXT,
     GoID_Cellular_component TEXT,
     GOSLIM_Molecular_Function TEXT,
     GoID_Molecular_Function TEXT,
     GOSLIM_Biological_Process TEXT,
     GoID_Biological_Process TEXT,
     Uniq_GOSlim_Cellular_Component TEXT,
     Uniq_GOSlim_Biological_Process TEXT,
     Uniq_GOSlim_Molecular_Function TEXT,
     Phenotype TEXT,
     Phenotype_Systematic_deletion TEXT,
     Haploinsuficiency TEXT,
     Viability TEXT,
     Oshea_abundance INTEGER,
     Oshea_localization TEXT,
     Ortho_MCL_family TEXT
);

CREATE TABLE gene2annotation (
     id INTEGER PRIMARY KEY AUTOINCREMENT,
     Systematic_name TEXT,
     ext_id TEXT,
     db_id TEXT,
     db_ref TEXT,
     FOREIGN KEY(Systematic_name) REFERENCES genes(Systematic_name) 
);

CREATE TABLE compounds (
     id INTEGER PRIMARY KEY AUTOINCREMENT,
     compound_id INTEGER UNIQUE,
     compound_name TEXT,
     IC30 REAL,
     wikipedia TEXT,
     pubmed TEXT,
     moa TEXT
);

CREATE TABLE experiments (
     id INTEGER PRIMARY KEY AUTOINCREMENT,
     experiment_type TEXT UNIQUE,
     experiment_group TEXT,
     type TEXT,
     experiment TEXT
);

CREATE TABLE compound2experiment (
     id INTEGER PRIMARY KEY AUTOINCREMENT,
     compound_concentration_experiment_type TEXT UNIQUE,
     compound_id INTEGER,
     experiment_type TEXT,
     concentration REAL,
     FOREIGN KEY(compound_id) REFERENCES compounds(compound_id),
     FOREIGN KEY(experiment_type) REFERENCES experiments(experiment_type)
);

CREATE TABLE hiphop (
     id INTEGER PRIMARY KEY AUTOINCREMENT,
     compound_concentration_experiment_type TEXT,
     gene_id TEXT,
     madl_score REAL, 
     z_score REAL,
     score_type TEXT,
     FOREIGN KEY(gene_id) REFERENCES genes(Systematic_name),
     FOREIGN KEY(compound_concentration_experiment_type) REFERENCES compound2experiment(compound_concentration_experiment_type)
);

CREATE TABLE gene_correlation (
     id INTEGER PRIMARY KEY AUTOINCREMENT,
     Cluster_ORF_1 TEXT,
     Type TEXT,
     Cluster_ORF_2 TEXT,
     Correlation REAL,
     Min_Z_Score_1_2 REAL,
     Min_NegLog_FDR_1_2 REAL,
     Z_Score_Gene1 REAL,
     Z_Score_Gene2 REAL,
     NegLog_Pval_Gene1 REAL,
     NegLog_FDR_Gene1 REAL,
     NegLog_Pval_Gene2 REAL,
     NegLog_FDR_Gene2 REAL,
     Self TEXT,
     Systematic_name1 TEXT,
     Viability1 TEXT,
     Systematic_name2 TEXT,
     Viability2 TEXT,
     FOREIGN KEY(Systematic_name1) REFERENCES genes(Systematic_name),
     FOREIGN KEY(Systematic_name2) REFERENCES genes(Systematic_name)
);

CREATE TABLE compound_correlation (
     id INTEGER PRIMARY KEY AUTOINCREMENT,
     compound_concentration_experiment_type1 TEXT,
     Type TEXT,
     compound_concentration_experiment_type2 TEXT,
     Correlation REAL,
     Min_Correlation REAL,
     Z_Score_1_2_min REAL,
     NegLog_FDR_1_2_min REAL,
     Z_Score_Cpd1 REAL,
     Min_Z_Score_Cpd1 REAL,
     Z_Score_Cpd2 REAL,
     Min_Z_Score_Cpd2 REAL,
     NegLog_Pval_Cpd1 REAL,
     NegLog_FDR_Cpd1 REAL,
     NegLog_Pval_Cpd2 REAL,
     NegLog_FDR_Cpd2 REAL,
     Self INTEGER,
     FOREIGN KEY(compound_concentration_experiment_type1) REFERENCES compound2experiment(compound_concentration_experiment_type),
     FOREIGN KEY(compound_concentration_experiment_type2) REFERENCES compound2experiment(compound_concentration_experiment_type)
);

CREATE INDEX compound_id_idx ON compound2experiment(compound_id);
CREATE INDEX compound_concentration_experiment_type_idx ON hiphop(compound_concentration_experiment_type);
CREATE INDEX gene_id_idx ON hiphop(gene_id);
CREATE INDEX Systematic_name1_idx ON gene_correlation(Systematic_name1);
CREATE INDEX compound_concentration_experiment_type1_idx ON compound_correlation(compound_concentration_experiment_type1);

CREATE VIEW experiments_v as
     select *
     from experiments,
          compound2experiment
     where
          experiments.experiment_type = compound2experiment.experiment_type;

CREATE VIEW hiphop_v as
     select hiphop.*, genes.Systematic_name, genes.Common_name, compounds.compound_id, compounds.compound_name,
               experiments.*, compound2experiment.*
     from hiphop,
          genes,
          compounds,
          experiments,
          compound2experiment
     where
          hiphop.gene_id = genes.Systematic_name and
          hiphop.compound_concentration_experiment_type = compound2experiment.compound_concentration_experiment_type and
          compound2experiment.experiment_type = experiments.experiment_type and
          compound2experiment.compound_id = compounds.compound_id;

CREATE VIEW gene_correlation_v as
     select gene_correlation.*, g1.Common_name as Common_name1, g2.Common_name as Common_name2
     from gene_correlation,
          genes as g1,
          genes as g2
     where
          gene_correlation.Systematic_name1 = g1.Systematic_name and
          gene_correlation.Systematic_name2 = g2.Systematic_name;

CREATE VIEW compound_correlation_v as
     select cc.*, c1.compound_id as compound_id1, c1.compound_name as compound_name1, 
               c2.compound_id as compound_id2, c2.compound_name as compound_name2
     from compound_correlation cc,
          compound2experiment ce1,
          compounds c1,
          compound2experiment ce2,
          compounds c2
     where
          cc.compound_concentration_experiment_type1 = ce1.compound_concentration_experiment_type and
          ce1.compound_id = c1.compound_id and
          cc.compound_concentration_experiment_type2 = ce2.compound_concentration_experiment_type and
          ce2.compound_id = c2.compound_id; 

.import E:/BigData/HipHop/reference_compounds.txt compounds_temp

.import E:/BigData/HipHop/reference_genes.txt genes_temp
.import E:/BigData/HipHop/reference_gene_annotation.txt gene2annotation_temp

.import E:/BigData/HipHop/full/HIP-scores-depivot-final.txt hiphop_temp
.import E:/BigData/HipHop/full/HOP-scores-depivot-final.txt hiphop_temp

.import E:/BigData/HipHop/full/CMB_Exp_HIP_gene_z-score_correlation_upto193_0.15_2.txt gene_correlation_temp
.import E:/BigData/HipHop/full/CMB_Exp_HOP_gene_z-score_correlation_upto193_0.15_2.txt gene_correlation_temp

.import E:/BigData/HipHop/full/HIPHOP_cpd_z-score_correlation_0.1_1.final.txt compound_correlation_temp

insert into genes ( Systematic_name, Common_name, Alias, Description, CMB_description, NN_Systematic_name, 
          NN_Common_name, NN_cor, NN_Description, NN_Type, EC_number, GeneID, RefSeqProteinID, UniProtID, 
          GOSLIM_Cellular_Component, GoID_Cellular_component, GOSLIM_Molecular_Function, GoID_Molecular_Function, 
          GOSLIM_Biological_Process, GoID_Biological_Process, Uniq_GOSlim_Cellular_Component, Uniq_GOSlim_Biological_Process, 
          Uniq_GOSlim_Molecular_Function, Phenotype, Phenotype_Systematic_deletion, Haploinsuficiency, Viability, 
          Oshea_abundance, Oshea_localization, Ortho_MCL_family )
     select Systematic_name, Common_name, Alias, Description, CMB_description, NN_Systematic_name, 
          NN_Common_name, NN_cor, NN_Description, NN_Type, EC_number, GeneID, RefSeqProteinID, UniProtID, 
          GOSLIM_Cellular_Component, GoID_Cellular_component, GOSLIM_Molecular_Function, GoID_Molecular_Function, 
          GOSLIM_Biological_Process, GoID_Biological_Process, Uniq_GOSlim_Cellular_Component, Uniq_GOSlim_Biological_Process, 
          Uniq_GOSlim_Molecular_Function, Phenotype, Phenotype_Systematic_deletion, Haploinsuficiency, Viability, 
          Oshea_abundance, Oshea_localization, Ortho_MCL_family from genes_temp;

insert into genes ( Systematic_name, Common_name, Description )
     select distinct Systematic_name1, Common_name1, 'Added from gene_correlation table'
     from gene_correlation_temp
     where Systematic_name1 not in ( select Systematic_name from genes );

insert into genes ( Systematic_name, Common_name, Description )
     select distinct Systematic_name2, Common_name2, 'Added from gene_correlation table'
     from gene_correlation_temp
     where Systematic_name2 not in ( select Systematic_name from genes );

insert into genes ( Systematic_name, Common_name, Description )
     select distinct gene_id, gene_id, 'Added from HIP HOP table'
     from hiphop_temp
     where gene_id not in ( select Systematic_name from genes );

update genes set Common_name = Systematic_name where Common_name='';

insert into gene2annotation ( Systematic_name, ext_id, db_id, db_ref )
     select distinct Systematic_name, ext_id, db_id, db_ref from gene2annotation_temp
     where Systematic_name in ( select Systematic_name from genes );

insert into compounds ( compound_id, compound_name, IC30, wikipedia, pubmed, moa )
     select * from compounds_temp;

insert into compounds ( compound_id, compound_name )
     select distinct compound_id, 'CMB' || cast(compound_id as TEXT)
     from hiphop_temp
     where compound_id not in ( select distinct compound_id from compounds );

insert into compounds ( compound_id, compound_name )
     select distinct CMB_Id_Cpd1, 'CMB' || cast(CMB_Id_Cpd1 as TEXT)
     from compound_correlation_temp
     where CMB_Id_Cpd1 not in ( select distinct compound_id from compounds );
     
insert into compounds ( compound_id, compound_name )
     select distinct CMB_Id_Cpd2, 'CMB' || cast(CMB_Id_Cpd2 as TEXT)
     from compound_correlation_temp
     where CMB_Id_Cpd2 not in ( select distinct compound_id from compounds);

insert into experiments ( experiment_type, experiment_group, type, experiment )
    select distinct experiment || '_' || experiment_type, experiment_group, experiment_type, experiment from hiphop_temp;

insert into compound2experiment ( compound_concentration_experiment_type, compound_id, experiment_type, concentration )
     select distinct compound_concentration_experiment || '_' || experiment_type, compound_id, 
          experiment || '_' || experiment_type, concentration
     from hiphop_temp;

insert into hiphop ( compound_concentration_experiment_type, gene_id, madl_score, z_score, score_type )
    select compound_concentration_experiment || '_' || experiment_type, gene_id, madl_score, z_score, score_type
    from hiphop_temp;

insert into gene_correlation ( Type, Correlation, Min_Z_Score_1_2, Min_NegLog_FDR_1_2,
         Z_Score_Gene1, Z_Score_Gene2, NegLog_Pval_Gene1, NegLog_FDR_Gene1, NegLog_Pval_Gene2, NegLog_FDR_Gene2,
         Self, Systematic_name1, Viability1, Systematic_name2, Viability2 )
    select Type, Correlation, Min_Z_Score_1_2, Min_NegLog_FDR_1_2,
         Z_Score_Gene1, Z_Score_Gene2, NegLog_Pval_Gene1, NegLog_FDR_Gene1, NegLog_Pval_Gene2, NegLog_FDR_Gene2,
         Self, Systematic_name1, Viability1, Systematic_name2, Viability2
    from gene_correlation_temp;

insert into compound_correlation ( Type, compound_concentration_experiment_type1, compound_concentration_experiment_type2, Correlation,
          Min_Correlation, Z_Score_1_2_min, NegLog_FDR_1_2_min, Z_Score_Cpd1, Min_Z_Score_Cpd1, Z_Score_Cpd2, Min_Z_Score_Cpd2, 
          NegLog_Pval_Cpd1, NegLog_FDR_Cpd1, NegLog_Pval_Cpd2, NegLog_FDR_Cpd2, Self )
     select Type, Cluster_Experiment1,Cluster_Experiment2,
          Correlation, Min_Correlation, Z_Score_1_2_min, NegLog_FDR_1_2_min, Z_Score_Cpd1, Min_Z_Score_Cpd1, Z_Score_Cpd2, 
          Min_Z_Score_Cpd2, NegLog_Pval_Cpd1, NegLog_FDR_Cpd1, NegLog_Pval_Cpd2, NegLog_FDR_Cpd2, Self
     from compound_correlation_temp;
